from setuptools import setup
from Cython.Build import cythonize

setup(
    ext_modules=cythonize(
        [
            "game.pyx",
            "items.pyx",
            "player.pyx",
            "noise.pyx",
            "utils.pyx",
            "widgets.pyx",
            "splashes.pyx",
        ]
    )
)
