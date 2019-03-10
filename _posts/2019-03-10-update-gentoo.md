---
layout: post
title:  "Keep Gentoo sane and not becoming insane"
date:   2019-03-10 12:00:00
categories: gentoo
---

Keeping updated a Gentoo instalation is a task quite a few difficult. In this post we learn how to keep up with the updates.

##### TL;DR

```bash
#!/bin/bash
eix-sync
emerge --update --deep --changed-use --newuse --with-bdeps=y @world --ask
emerge @preserved-rebuild
emerge --depclean --ask
revdep-rebuild
revdep-rebuild.sh -u --pretend
```
[See Gist](https://gist.github.com/mercuriete/650a7d4431ba4ec660ff59ab4b3365ff)

##### Eix-sync
eix-sync is a amazing tool that allows us to download the new state of portage. Doing an analogy to debian based distros is similar to ```apt-get update```.

In addition, checks the differences between the last time you launch that command and show you problems with your installed packages.

```
* Calling eix-diff
[U]  ==  dev-libs/openssl  (1.0.2q@03/03/19;  0.9.8z_p8-r1(0.9.8)^d  1.0.2q^d  ->  0.9.8z_p8-r1(0.9.8)^d  1.0.2r^d): full-strength general purpose cryptography li
brary (including SSL and TLS)
[>]  ==  sys-power/bbswitch  (0.8-r1  ->  0.8-r2): Toggle discrete NVIDIA Optimus graphics card
* Time statistics:
26 seconds for syncing
7 seconds for eix-update
1 seconds for eix-diff
34 seconds total
```

For example, in this time, we got updates for the package called openssl that is already installed and bbswitch that is not installed in our system.

There are several codes for package status:
* **[U]:** the package is installed and there is a new update available.
* **[>]:** there are new updates for a package that is not installed (useless information but nice to know it).
* **[<]:** Gentoo stop supporting a package and is not in portage anymore. You can keep your package installed but probably in a few month a dependency problem will appear and you will be forced to search an alternative.
* **[?]:** There is something wrong with your package. Usully this means you have an unstable package installed and is only unmasked for a given version. The system is telling you that you need to update by hand this package unmasking a new version of this package.
* **[UD]:** You had a unstable version installed but you forgot to update and now there is a new "old" version stable and the system is forcing you to downgrade. The solution is downgrade or unmask a new version.

Is very important to read carefully the information given by this command because if you ignore it, you will have problems in the future.

##### Emerge --update --wtf_are_those_arguments
This command is already in the official documentation: [See documentation](https://wiki.gentoo.org/wiki/Gentoo_Cheat_Sheet#Package_upgrades)
* **--update:** we are going to update packages
* **--deep:** we are searching through the dependency tree in DFS (deep search) looking for dependency updates
* **--changed-use:** we will rebuild a package that is not updated but you changed the USE flags that are affecting to this package.
* **--newuse:** we will rebuild a package that is not updated but someone (usually the package mantainer) adds a new USE flag.
* **--with-bdeps=y:** we will be updating the build deps and not only the runtime deps. For example, gcc, g++, bison, flex, are usually build dependencies but not used in runtime. Keep your toolchain updated is very important for new optimizations and stability.
* **@world:** This is the package set you want to update, you can put here a single package or a set. World package means "all installed packages by me":  [See documentation](https://wiki.gentoo.org/wiki/World_set_(Portage))
* **--ask:** Stupid mode. The command treats you as a stupid and ask everything. This argument is very important because It resolves unmasking problems such as a package is requesting an unstable package or you are trying to install a privative package without accepting the EULA (for example chrome-binary-plugins if you want see netflix)

##### emerge @preserved-rebuild
Sometimes, hardly ever, you will encounter a weird problem.

You are updating a given library but some other package depends on this, the system detects that there are some linking incompatibility and the system keeps two copies of the library for avoid break the application.

What emerge preserved-rebuild does is rebuild all applications that depends on this library in order to be able to delete the "preserved library".

This not happens very often because emerge rebuilds applications automatically, this only happens when the emerge process is stopped badly and you don't gave It the opportunity to keep the system in a sane state.

##### emerge --depclean --ask
This deletes orphan packages (packages installed that nobody want them).

If you are a debian based user, this is similar to ```apt-get autoremove```.
--ask argument stops the execution and prompt you a Yes/No confirmation, useful to avoid delete packages that you want to keep but you forgot to rebuild the application with that version of the library. This usually happens when you update llvm but you forgot to rebuild mesa.

##### revdep-rebuild
This command is very useful to keep your applications in a sane state.

What this command does is keep the links working properly. [See documentation](https://wiki.gentoo.org/wiki/Gentoolkit/es#revdep-rebuild)
1. Iterate over all applications
2. check the links that points to shared libraries
3. If the link is broken check to what package belongs that file
4. Installs or rebuild the library package

This situation is not very common but when It happen is difficult to track down.

##### revdep-rebuild -u --pretend
This command is very important, It will save you hours and hours of debugging and frustration.

What this command does is:
1. Iterate over all applications
2. Check all dinamic libraries and symbols that are exported from the library and imported to the application required to work. like: ```readelf -d $executable | grep 'NEEDED'```
3. Figure out what package contains that library. like: ```equery belongs $file```
4. Suggest you to rebuild that package.

This problem should never appears but the reality is that you can have problems with the hard drive (corrupted files), or you can have a big update of gcc.

When this events happens, you think your dependencies are correct but in reality the symbols that exports the library are different breaking the ABI and the application got broken.

With this advise you can avoid a full system recompilation that is suggested in official documentation: [See documentation](https://wiki.gentoo.org/wiki/Upgrading_GCC#ABI_changes)

##### Conclusions
The Gentoo official documentation is great but is splited in several locations so you have to learn which combination of commands are suitable for you.

In addition, keeping up with the updates without breaking the system is difficult so this is why Gentoo is not the best distribution for newbies.

Given that, the decision of moving from a given gcc version to another is something that someone have to do. I mean wheather you are building your packages or a package mantainer are building this for you, ABI changes are problem that someone have to solve. The only difference between Ubuntu and Gentoo is that those problems are resolved by other people that are not you, but the problems is still there.

With Gentoo you will learn more about linking problems, ABI breakages and some other problems that you are not facing in a binary distribution like Ubuntu or Windows or MacOSX


I Hope you enjoy this post.

