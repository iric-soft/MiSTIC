import math



def safeFloat(x):
    if math.isinf(x):
        if x < 0:
            return "-Infinity"
        else:
            return "Infinity"
    if math.isnan(x):
        return "NaN"
    return x



__all__ = [
    'safeFloat',
]
