import setuptools

setuptools.setup(
    name="bwtool",
    version="1.0.0",
    author="Jaap Heijligers",
    description="SOCKS proxy bandwidth measuring tool",
    packages=setuptools.find_packages(),
    install_requires=[
        'python_socks'
    ],
    scripts=['bwtool.py', 'bwplotter.py', 'bwtables.py']
)
