# **Skyrim SE - D4SCO ENB - 0.0.0**

Thank you for being curious and/or lost enough to check out my work - here's a quick rundown
of the main information you'll need to understand what's going on :)

## What ?

This is - or should become at the very least - a set of effects (and eventually a preset)
specifically made for the game Skyrim (Special Edition) and requires the installation of
[ENBSeries](http://enbdev.com/) by Boris Vorontsov to work. As such, you'll eventually need
both the game itself and the mod, although by the time D4SCO is ready to be used I'll have
a proper, explicative, Nexus page setup around [these](https://www.nexusmods.com/skyrimspecialedition/mods/categories/97/) parts.

Note that as long as we haven't reached the first major version, the files available on
the master branch will be exactly the same as the ones you can download from enbdev, minus the
binaries as per Boris' license. While I don't technically *need* them here, they are as
far as I know free to redistribute without the binaries - and I like having them as a
guideline.

## Why ?

For two main reasons:

* It gives me the opportunity to learn and experiment with HLSL in a smaller, more controlled
context than a full blown game engine and/or renderer
* I have yet to find a preset I don't find any issue with on the previously linked Nexus - more details below

Now, "issues" is a *strong* word, and in truth I greatly appreciate the time and effort
put into these by their respective authors - most of the issues in question are most of the time
because of Skyrim itself rather than any fault of the modder. Add to that that I'm talking about issues
*I* am having, rather than full-blown bad decisions or technical issues due to a faulty implementation.

The goals of D4SCO pertaining to that point are the following :

* to be fully weather-mod agnostic, meaning that most of the difference between weather presets (if I 
make multiple ones) will be color tweaking - while specific per-weather configurations are great, there's often a missed weather variant or uncovered update that makes it hard to find an all-around good-to-great preset
* to not break the horizon seam fixes implemented by [Obsidian](https://www.nexusmods.com/skyrimspecialedition/mods/12125) and [Cathedral](https://www.nexusmods.com/skyrimspecialedition/mods/24791) weathers, that being *the* thing that pushed me to do this
* to not break the vanilla night vision, without resorting to hacky fixes and leaving the choice
to the end-user

I'm not going to go into details for now about the artistic side of things - first because
each is entitled to their preference as far as visual style goes, second because I don't
know enough yet to make myself a clear-cut and realistic roadmap preset-wise. At worst, I'll link
this repo to the folks over at the ENBSeries [forums](http://enbseries.enbdev.com/forum/) - 
they'll probably know better than me how to fix what I would most certainly break.

## How ?

Everything will be done in HLSL, Microsoft's shader language for DirectX applications. As far as workflow
goes, I'm still figuring it out, but I have a Linear workspace setup and am trying to do all of
this in a clean way :)

## When ?

No point in putting up any kind of estimate when I can't properly anticipate a 5 minute walk :p

More seriously though, I'll have a better overview of what is coming first at least in the near
future - estimates will come afterwards if possible.
