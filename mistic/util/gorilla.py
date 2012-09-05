import numpy

# input: a vector of 1's and 0's.

def gorilla(vec):
  if type(vec) is not numpy.ndarray:
    vec = numpy.array(vec)
  if len(vec.shape) != 1:
    return -1
  if not set(vec) <= set((0,1)):
    return -1
  n_1 = vec.sum()
  n_0 = vec.shape[0] - n_1

  n = n_0 + n_1

  p = numpy.zeros((n_0+1, n_1+1))
  p[0,0] = 1.0

  for i_0 in range(1, n_0+1):
    p[i_0,0] = float(n_0 - (i_0-1)) / (n - (i_0-1)) * p[i_0-1,0]

  for i_1 in range(1, n_1+1):
    p[0,i_1] = float(n_1 - (i_1-1)) / (n - (i_1-1)) * p[0,i_1-1]

  for i_0 in range(1, n_0+1):
    for i_1 in range(1, n_1+1):
      p_0 = float(n_0 - (i_0-1)) / (n - (i_0-1) - i_1)
      p_1 = float(n_1 - (i_1-1)) / (n - i_0 - (i_1-1))
      p[i_0,i_1] = p_0 * p[i_0-1, i_1] + p_1 * p[i_0, i_1-1]

  pvec = numpy.zeros(vec.shape[0])

  c_0 = 0
  c_1 = 0
  p_min = 1.1

  
  c_0_best = 0
  n_best = 0
  for i in range(vec.shape[0]):
    if vec[i] == 0:
      c_0 += 1
    else:
      c_1 += 1
    pvec[i] = p[c_0,c_1]
    if pvec[i] < p_min:
      p_min = pvec[i]
      c_0_best = c_0
      n_best = c_0 + c_1

  return pvec, p_min, ((c_0_best, n_best), (n_0, n))
