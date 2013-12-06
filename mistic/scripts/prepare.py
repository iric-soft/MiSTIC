import sys
import os
import re
import time
import argparse
import collections
import exceptions
import ConfigParser
import multiprocessing
import subprocess
from mistic.app import data
from mistic.scripts.helpers import *

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
      print "NOT RUNNABLE: %s for %s " % (self.cmd[0], os.path.basename(self.cmd[-1]).replace("g.input.dot", "") )
      return NOT_RUNNABLE

    # check if already up to date
    if not self.needsToRun():
      print "NO NEED TO RUN : %s for %s " % (self.cmd[0], os.path.basename(self.cmd[-1]).replace("g.input.dot", "")) 
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
    t0= time.time()
    print "CONFIG : %s  ; %s" % ( self.n_parallel_jobs, self.noparallel_roots)
    self.printState()
    while self.tasksRemain():
      while len(self.task_state[self.RUNNING]) >= self.n_parallel_jobs:
        self.finalizeOneTask()
      
      task = self.selectTask()
      t1 = time.time()
      
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
      print "time : ", task.cmd[0], task.cmd[-1].split('transformed/')[1].split('/')[0], time.time()-t1
      
    self.finalizeAllTasks()

    sys.stdout.write('\n')
   
    print 'completed tasks:' , len(self.task_state[self.COMPLETED])
    print '   failed tasks:' , len(self.task_state[self.FAILED])
    print'time elapsed: ' , time.time()-t0

def init_parser(parser):
  parser.add_argument('-j', '--jobs',      type=int, help='number of parallel jobs', default=1)
  parser.add_argument('-p', '--par-mst',   action='store_true', help='run mst jobs in parallel', default=False)
  parser.add_argument('-n', '--app-name',  type=str, help='Load the named application', default='main')
  parser.add_argument('config',            type=argparse.FileType('r'), help='config file')

def run(args):
  defaults = dict(
    here = os.path.dirname(os.path.abspath(args.config.name)),
    __file__ = os.path.abspath(args.config.name)
  )

  init_logging(args.config, defaults)
  init_beaker_cache()

  config = {}

  settings = read_config(args.config, 'app:' + args.app_name, defaults)

  if 'mistic.data' not in settings:
    raise exceptions.RuntimeError('no dataset configuration supplied')

  APP_DATA = data.GlobalConfig(settings['mistic.data'])

  task_list = []

  PREPARE = read_config(args.config, 'mistic:prepare', defaults)

  TRANSFORM =    tuple(PREPARE['transform'].split())
  MST =          tuple(PREPARE['mst'].split())
  GRAPH_TO_DOT = tuple(PREPARE['graph-to-dot'].split())
  LAYOUT =       tuple(PREPARE['layout'].split())

  for dataset in APP_DATA.config['datasets']:
    if 'path' not in dataset:
      raise exceptions.RuntimeError('no path for dataset ' + dataset.get('id', '????'))

    base = APP_DATA.file_path(dataset.get('path'))
    if base is None:
      continue
    basedir, basefile = os.path.split(base)

    transforms = set(('none', 'log', 'anscombe', 'rank')) & set(dataset.get('xfrm', []))

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
    print 'FAILED : ', ' '.join(failed.cmd)

__all__ = [ 'cmd', 'init_parser', 'run' ]
