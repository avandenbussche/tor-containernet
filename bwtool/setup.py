import setuptools

setuptools.setup(
    name="bwtool",
    version="1.0.0",
    author="Jaap Heijligers",
    description="SOCKS proxy bandwidth measuring tool",
    packages=setuptools.find_packages(),
    scripts=['bwtool.py']
)
