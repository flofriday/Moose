import time

def fib(n):
  if n <= 1:
    return n
  return fib(n-1) + fib(n - 2)


n = time.time()

i = 30
print(f"{i}: {fib(i)}")

print(time.time() - n)