class DisjointSet(object):
  def __init__(self, N):
    self.reset(N)

  def find_set_head(self, a):
    if a == self.set[a][0]: return a
    set_a = self.set[a]

    a_head = a
    a_parent = self.set[a][0]

    while self.set[a_head][0] != a_head:
      a_head = self.set[a_head][0]

    if a_parent != a_head:
      set_a_parent = self.set[a_parent]
      self.set[a_parent] = ( set_a_parent[0], set_a_parent[1], set_a_parent[2] - set_a[2] )
      self.set[a] = ( a_head, set_a[1], set_a[2] )

    return a_head

  def same_set(self, a, b):
    return self.find_set_head(a) == self.find_set_head(b)

  def set_size(self, a):
    return self.set[self.find_set_head(a)][2]

  def merge_sets(self, a, b):
    a = self.find_set_head(a)
    b = self.find_set_head(b)
    if a == b:
      return a

    self.n_sets -= 1

    set_a = self.set[a]
    set_b = self.set[b]

    if set_a[1] < set_b[1]:
      self.set[a] = (b, set_a[1], set_a[2])
      self.set[b] = (b, set_b[1], set_a[2] + set_b[2])
      return b

    elif self.set[b][1] < self.set[a][1]:
      self.set[b] = (a, set_b[1], set_b[2])
      self.set[a] = (a, set_a[1], set_a[2] + set_b[2])
      return a

    else:
      self.set[a] = (a, set_a[1] + 1, set_a[2] + set_b[2])
      self.set[b] = (a, set_b[1], set_b[2])
      return a

  def reset(self, N):
    self.set = [ (i, 0, 1) for i in range(N) ]
    self.n_sets = N



__all__ = [
  'DisjointSet'
]
