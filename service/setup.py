from setuptools import setup, find_packages


setup(
    name='baked-pdf',
    packages=find_packages(),
    entry_points={
        'console_scripts': [
            'baked-pdf = bakedpdf.__main__:main',
        ],
    },
    install_requires=(
        'pika >= 0.11.0',
    ),
    setup_requires=(
        'pytest-runner',
    ),
    tests_require=(
        'pytest',
    ),
)
