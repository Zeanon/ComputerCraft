# Disclaimer/Credit
This program is not originally by me but a fork of [this](https://github.com/acidjazz/drmon/) program written by [acidjazz](https://github.com/acidjazz/), so full credit for the base of the program to him.

# DraconicReactorControl
## Reactor Setup
the Setup needs: 
<br>-a fully working reactor 
<br>-one flux gate on the energy infuser(internalInput)
<br>-two fluxgates on the output(internalOutput, which should power the buffer energy core and externalOutput which is the external output)
<br>-one energy core as a buffer(with more than 2.000.000RF storage)
<br>make sure that there is no other monitor, energy core or reactor connected to the same network or the autodetection of these items will not work properly

## Installation
pastebin URL of install script: https://pastebin.com/qpA31HT6
<br>use <code>pastebin get qpA31HT6 install</code> and then run install
<br>to update just run <code>update</code>

## Run
to run the program you don't have to do anything, the install script will do everything for you.
<br>to kill the program just hold down ctrl+t twice or delete startup and then reboot the System.
<br>if you happen, to use two reactors, you can use the [DraconicReactorGenerationOverview](https://github.com/Zeanon/ComputerCraft/tree/master/legacy/DraconicReactorGenerationOverview/) program I wrote, to monitor their total stats.
