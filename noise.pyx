from math import floor

cdef unsigned hash(unsigned x):
	x ^= x >> 16
	x *= <unsigned>0x7feb352d
	x ^= x >> 15
	x *= <unsigned>0x846ca68b
	x ^= x >> 16
	return x

cdef float fade(float t):
	return t * t * t * (t*(t*6 - 15) + 10)

cdef float lerp(float t, float a, float b):
	return a + (b - a)*t

cdef float gen_grad_2d(unsigned h, int x, int y, float dx, float dy):
	h = hash(hash(h + hash(x)) + hash(y))
	return (dx if (h & 1) else -dx) + (dy if (h & 2) else -dy)

cdef float gen_grad_1d(unsigned h, int x, float dx):
	h = hash(h + hash(x))
	return (dx if (h & 1) else -dx)

cdef float perlin1d_c(unsigned h, float x):
	cdef int X = floor(x)
	x -= X
	cdef float u = fade(x)
	return lerp(u, gen_grad_1d(h, X, x), gen_grad_1d(h, X+1, x-1))

cdef float perlin2d_c(unsigned h, float x, float y):
	cdef int X = floor(x)
	cdef int Y = floor(y)
	#cdef int Z = math.floor(z) & 255
	x -= X
	y -= Y
	#z -= math.floor(z)
	cdef float u = fade(x)
	cdef float v = fade(y)
	#cdef float w = fade(z)
	return lerp(v,
		lerp(u,
			gen_grad_2d(h, X, Y, x, y),
			gen_grad_2d(h, X+1, Y, x-1, y)),
		lerp(u,
			gen_grad_2d(h, X, Y+1, x, y-1),
			gen_grad_2d(h, X+1, Y+1, x-1, y-1)))

def perlin1d(h, x):
	return perlin1d_c(h, x)

def perlin2d(h, x, y):
	return perlin2d_c(h, x, y)

class Noise1D():
	def __init__(self, func):
		self.func = func

	def __call__(self, h, x):
		return self.func(h, x)

	def __abs__(self):
		return Noise1D(lambda h, x: abs(self(h, x)))

	def __add__(self, other):
		if '__call__' in dir(other):
			return Noise1D(lambda h, x: self(h, x) + other(h, x) )
		else:
			return Noise1D(lambda h, x: self(h, x) + other)

	def __sub__(self, other):
		if '__call__' in dir(other):
			return Noise1D(lambda h, x: self(h, x) - other(h, x) )
		else:
			return Noise1D(lambda h, x: self(h, x) - other)

	def __rsub__(self, other):
		return Noise1D(lambda h, x: other - self(h, x))

	def __mul__(self, other):
		if '__call__' in dir(other):
			return Noise1D(lambda h, x: self(h, x) * other(h, x) )
		else:
			return Noise1D(lambda h, x: self(h, x) * other)

	def __div__(self, other):
		if '__call__' in dir(other):
			return Noise1D(lambda h, x: self(h, x) / other(h, x) )
		else:
			return Noise1D(lambda h, x: self(h, x) / other)

	def __mod__(self, other):
		if '__call__' in dir(other):
			return Noise1D(lambda h, x: self(h, x) % other(h, x) )
		else:
			return Noise1D(lambda h, x: self(h, x) % other)

	def scale(self, k):
		return Noise1D(lambda h, x: self(h, k*x))

	def rehash(self):
		return Noise1D(lambda h, x: self(hash(h), x))


class Noise2D():
	def __init__(self, func):
		self.func = func

	def __call__(self, h, x, y):
		return self.func(h, x, y)

	def __abs__(self):
		return Noise2D(lambda h, x, y: abs(self(h, x, y)))

	def __add__(self, other):
		if '__call__' in dir(other):
			return Noise2D(lambda h, x, y: self(h, x, y) + other(h, x, y) )
		else:
			return Noise2D(lambda h, x, y: self(h, x, y) + other)

	def __sub__(self, other):
		if '__call__' in dir(other):
			return Noise2D(lambda h, x, y: self(h, x, y) - other(h, x, y) )
		else:
			return Noise2D(lambda h, x, y: self(h, x, y) - other)

	def __rsub__(self, other):
		return Noise2D(lambda h, x, y: other - self(h, x, y))

	def __mul__(self, other):
		if '__call__' in dir(other):
			return Noise2D(lambda h, x, y: self(h, x, y) * other(h, x, y) )
		else:
			return Noise2D(lambda h, x, y: self(h, x, y) * other)

	def __div__(self, other):
		if '__call__' in dir(other):
			return Noise2D(lambda h, x, y: self(h, x, y) / other(h, x, y) )
		else:
			return Noise2D(lambda h, x, y: self(h, x, y) / other)

	def __mod__(self, other):
		if '__call__' in dir(other):
			return Noise2D(lambda h, x, y: self(h, x, y) % other(h, x, y) )
		else:
			return Noise2D(lambda h, x, y: self(h, x, y) % other)

	def scale(self, k):
		return Noise2D(lambda h, x, y: self(h, k*x, k*y))

	def rehash(self):
		return Noise2D(lambda h, x, y: self(hash(h), x, y))

def brownian(noise, lac, per, oct):
	total = noise
	for i in range(1, oct):
		total += noise.scale(per**i) * (per**i)
	return total
