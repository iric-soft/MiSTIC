import sys
import os
import re
import argparse
import collections
import exceptions
import ConfigParser
import multiprocessing
import subprocess
from mistic.app.data import collectItems

cmd = 'prepare'


NOT_RUNNABLE = 65536

class Task(object):
  def __init__(self, cmd, inputs, outputs, **kw):
    self.cmd = cmd
    self.inputs = inputs
    self.outputs = outputs
    self.noparallel = bool(kw.get('noparallel', False))

  def canRun(self):
    return all([ os.path.exists(input) for input in self.inputs ])

  def needsToRun(self):
    if not self.canRun():
      return True

    if any([ not os.path.exists(output) for output in self.outputs ]):
      return True

    input_mtime = max([ os.path.getmtime(input) for input in self.inputs ])
    output_mtime = min([ os.path.getmtime(output) for output in self.outputs ])

    return input_mtime >= output_mtime

  def dependsOn(self, other):
    return len(set(self.inputs) & set(other.outputs)) > 0

  def run(self):
    # check prerequisites are satisfied
    if not self.canRun():
      return NOT_RUNNABLE

    # check if already up to date
    if not self.needsToRun():
      return 0

    try:
      print '[' + self.id + ']', 'RUN', ' '.join(self.cmd)
      return subprocess.call(self.cmd)
    except OSError:
      return NOT_RUNNABLE



class TaskRunner(object):
  WAITING = 0
  READY = 1
  RUNNING = 2
  COMPLETED = 3
  FAILED = 4

  def __init__(self, task_list, **kw):
    self.n_parallel_jobs = max(1, int(kw.get('n_parallel', 1)))
    self.completion_queue = multiprocessing.Queue()
    self.task_list = tuple(task_list)
    self.initTaskDependencies()

  def initTaskDependencies(self):
    self.children = collections.defaultdict(set)
    self.parents = collections.defaultdict(set)
    self.noparallel_roots = []
    self.current_processes = {}

    self.task_state = collections.defaultdict(set)

    for task1 in self.task_list:
      for task2 in self.task_list:
        if task2.dependsOn(task1):
          self.children[task1].add(task2)
          self.parents[task2].add(task1)

    for task in self.task_list:
      if not len(self.parents[task]):
        self.task_state[self.READY].add(task)
      else:
        self.task_state[self.WAITING].add(task)

  def stateString(self):
    result = ''
    for task in self.task_list:
      for s, ch in ((self.WAITING,   '.'),
                    (self.READY,     '+'),
                    (self.RUNNING,   'R'),
                    (self.COMPLETED, 'Y'),
                    (self.FAILED,    'N')):
        if task in self.task_state[s]:
          result += ch
          break
      else:
        result += '?'
    return result

  def tasksRemain(self):
    return len(self.task_state[self.WAITING]) + len(self.task_state[self.READY]) > 0

  def selectTask(self):
    candidates = set()
    failures = set()
    for task in self.task_state[self.READY]:
      if self.task_state[self.COMPLETED] >= self.parents[task]:
        # can run
        candidates.add(task)
      elif len(self.task_state[self.FAILED] & self.parents[task]):
        # fail this task too
        failures.add(task)
      # can't run yet (parents are still running)

    for task in failures:
      self.updateState(task, self.READY, self.FAILED)

    if not len(candidates):
      return None

    for c in candidates:
      if not c.noparallel: return c

    return candidates.pop()

  @staticmethod
  def _execute(task, completion_queue):
    completion_queue.put((task.id, task.run()))

  def executeTask(self, task):
    self.updateState(task, self.READY, self.RUNNING)
    p = multiprocessing.Process(target = self._execute, args = (task, self.completion_queue))
    task.id = p.name
    self.current_processes[p.name] = p
    p.start()

  def printState(self):
    print 'WAIT:', len(self.task_state[self.WAITING]),
    print 'READY:', len(self.task_state[self.READY]),
    print 'RUN:', len(self.task_state[self.RUNNING]),
    print 'DONE:', len(self.task_state[self.COMPLETED]),
    print 'FAIL:', len(self.task_state[self.FAILED])

  def updateState(self, task, old_state, new_state):
    self.task_state[old_state].remove(task)
    self.task_state[new_state].add(task)
    self.printState()

  def finalizeOneTask(self):
    task_id, result = self.completion_queue.get()
    matching_tasks = [ t for t in self.task_state[self.RUNNING] if t.id == task_id ]
    assert len(matching_tasks) == 1
    task = matching_tasks[0]

    self.current_processes.pop(task_id).join()

    if result == 0:
      self.updateState(task, self.RUNNING, self.COMPLETED)
    else:
      self.updateState(task, self.RUNNING, self.FAILED)

    for child_task in self.children[task]:
      self.parents[child_task].remove(task)
      if not len(self.parents[child_task]):
        self.updateState(child_task, self.WAITING, self.READY)

    del self.parents[task]
    del self.children[task]

  def finalizeAllTasks(self):
    while len(self.task_state[self.RUNNING]):
      self.finalizeOneTask()

  def run(self):
    self.printState()
    while self.tasksRemain():
      while len(self.task_state[self.RUNNING]) >= self.n_parallel_jobs:
        self.finalizeOneTask()

      task = self.selectTask()

      while task is None:
        if len(self.task_state[self.RUNNING]) == 0:
          break
        self.finalizeOneTask()
        task = self.selectTask()

      if task is None:
        break

      if task.noparallel and task.needsToRun():
        self.finalizeAllTasks()
        self.executeTask(task)
        self.finalizeOneTask()
      else:
        self.executeTask(task)

    self.finalizeAllTasks()

    sys.stdout.write('\n')

    print 'completed tasks:' , len(self.task_state[self.COMPLETED])
    print '   failed tasks:' , len(self.task_state[self.FAILED])

def init_parser(parser):
  parser.add_argument('-j', '--jobs',      type=int, help='number of parallel jobs', default=1)
  parser.add_argument('-p', '--par-mst',   action='store_true', help='run mst jobs in parallel', default=False)
  parser.add_argument('config',            type=argparse.FileType('r'), help='config file')

def read_config(config, section, defaults):
  result = {}

  p = ConfigParser.ConfigParser(defaults = defaults)
  p.readfp(config)

  if p.has_section(section):
    for key, value in p.items(section):
      if key.endswith('__eval__'):
        result[key[:-len('__eval__')]] = eval(value)
      else:
        result[key] = value

  return result

def run(args):
  config = {}

  defaults = dict(
    here = os.path.dirname(os.path.abspath(args.config.name)),
    __file__ = os.path.abspath(args.config.name)
  )

  config = read_config(args.config, 'app:main', defaults)

  task_list = []

  TRANSFORM =    tuple(config['mistic.prepare.transform'].split())
  MST =          tuple(config['mistic.prepare.mst'].split())
  GRAPH_TO_DOT = tuple(config['mistic.prepare.graph-to-dot'].split())
  LAYOUT =       tuple(config['mistic.prepare.layout'].split())

  for dataset in collectItems(config, 'mistic.dataset.'):
    base = dataset.get('file')
    if base is None:
      continue
    basedir, basefile = os.path.split(base)

    transforms = set(('none', 'log', 'anscombe', 'rank')) & set(re.split(r'\s*,\s*', dataset.get('xfrm', 'none').strip()))

    for t in transforms:
      transformed = os.path.join(basedir, 'transformed', t, basefile)
      graph = os.path.splitext(transformed)[0] + '.g'
      dot_input = os.path.splitext(transformed)[0] + '.input.dot'
      dot_output = os.path.splitext(transformed)[0] + '.output.dot'

      task_list.append(Task(
          TRANSFORM + (t, base, transformed),
          (base, args.config.name),
          (transformed,)))

      task_list.append(Task(
          MST + ('-m', transformed, '-g', graph),
          (transformed,),
          (graph,),
          noparallel=not args.par_mst))

      task_list.append(Task(
          GRAPH_TO_DOT + (graph, dot_input),
          (graph,),
          (dot_input,)))

      task_list.append(Task(
          LAYOUT + ('-v', '-Tdot', '-o' + dot_output, dot_input),
          (dot_input,),
          (dot_output,)))

  runner = TaskRunner(task_list, n_parallel = args.jobs)
  runner.run()

  for failed in runner.task_state[TaskRunner.FAILED]:
    print ' '.join(failed.cmd)

__all__ = [ 'cmd', 'init_parser', 'run' ]
