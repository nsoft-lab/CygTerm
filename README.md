# <img src="cygterm-logo.gif" align="absmiddle" height="100"> Cygwin console with a terminal emulator
v1.08a - 2017/03/31 &nbsp; Copyright(C) 2000-2017 NSym.

= English / [Japanese](README.ja.md) =

## Overview of CygTerm

In Cygwin, you can use a shell such as bash on the DOS window. However, using on the DOS window is inconvenient when you want to do window resizing, copy & paste, or etc.

I guess many people may use Unix machines with a terminal emulator via Telnet. It is convenient to use Cygwin in the same way as it, that is to operate with a VT100 terminal emulator. At first you think that preparing inetd, in.telnetd and so on in Cygwin and login from a terminal emulator...

But, here is another approach. In short it is to connect a terminal emulator and Cygwin shell directly. You simply use a terminal emulator instead of cygwin.bat DOS window without login.

## Idea

The idea is to make a program which performs starting a terminal emulator and Cygwin shell, and relaying their I/O. When you run this program a specified terminal emulator starts up and the Cygwin shell command line prompt appears in it.  
[screen shot](cygterm-shot.gif)

## Design

### Details of cygterm.exe

| Step | Description |
| :--- | :--- |
| **\[1\]** | Prepare a listener socket to wait for a TELNET connection. Find out an unused TCP port number to assign to the socket from a specified range. |
| **\[2\]** | Invoke a terminal emulator in another thread. Then specify IP address `127.0.0.1` and the port number \[1\] in the command line arguments. |
| **\[3\]** | Accept the connection from the terminal emulator. Refuse it except a connection from `127.0.0.1` in security. |
| **\[4\]** | Do `fork()`, and in the child process, invoke a shell under PTY (pseudo terminal) slave side. |
| **\[5\]** | Relay I/O between the TELNET connection socket \[3\] and the PTY master side of \[4\]. |

### Support for TELNET protocol (options negotiation)

* Receive the notification of terminal-type from a terminal emulator, and apply it to the environment variable `TERM` on a shell.
* Receive the notification of terminal-size from a terminal emulator, and apply it to window size of PTY.
* \[Ref. RFC854 TELNET PROTOCOL SPECIFICATION\]
* `cygterm.exe` is implemented as an window-less Win32 application.

## Download

Source Files

| File | Description |
| :--- | :--- |
| `Makefile` | MAKEFILE for installation |
| `cygterm.cc` | program source code |
| `cygterm.cfg` | configuration file |
| `cygterm_here.reg` | sample registry file for Explorer right click |

[Download cygterm108a.tgz (about 8kb)](https://github.com/nsoft-lab/CygTerm/releases/download/v1.08a/cygterm108a.tgz)

> **--- License ---**  
> CygTerm is a free software distributed under the terms of the **GNU General Public License (GPL)** published by Free Software Foundation. See [GPL (http://www.gnu.org/copyleft/gpl.html)](http://www.gnu.org/copyleft/gpl.html).  
>   
> **--- Note ---**  
> Any program including non-GPL program can invoke the CygTerm executable (`cygterm.exe`) and communicate with it.

## Install

Do `make install` under Cygwin.

> Be sure to specify the install directory by `BINDIR` in Makefile in advance. `cygterm.exe` and `cygterm.cfg` are installed in `BINDIR`. `cygterm.cfg` is not overwritten.

> Do `make with-icon; make install` if you want to add Cygwin icon.

## Configuration

`cygterm.cfg` is a configuration file. This includes definitions for the command lines of a terminal emulator and a shell, and several parameters. `cygterm.cfg` is loaded from the same directory `cygterm.exe` exists in.

```
An example of cygterm.cfg      
+-----------------------------------------------------------------------      
| TERM = C:\program files\ttermpro\ttermpro.exe %s %d /KR=SJIS /KT=SJIS      
| TERM_TYPE = vt100      
| PORT_START = 20000      
| PORT_RANGE = 40      
| SHELL = /bin/bash      
| ENV_1 = MAKE_MODE=unix      
| ENV_2 = HOME=/home      
|   :         :
```

* **`TERM`**: This is the command line to execute a terminal emulator. Specify the full path to the command if it isn't in Windows search path. This needs to be described `%s` and `%d` for the host and port number.
* **`TERM_TYPE`**: This terminal type is adopted when the terminal emulator did not give a terminal type. (default: `vt100`) Then this value is set to the environment variable `TERM` on a shell.
* **`PORT_START`**: This is the minimum TCP port number allowed for use. (default: `20000`)
* **`PORT_RANGE`**: This is the maximum number of TCP ports allowed for use. (default: `40`) `cygterm.exe` looks for an unused port number between `PORT_START` and `PORT_START+PORT_RANGE`, and therefore can be run concurrently as many as this number.
* **`SHELL`**: This is the command line to execute a shell in Cygwin side (normally `/bin/bash`). Specify the full path to the shell.
* **`ENV_X`**: This is the environment variable to be set when starting the shell. It should be of the form `name=value` (like putenv). It is possible to give as many environment variables as needed by beginning with `ENV_`.

## Usage

### Command Line Options

```
cygterm.exe [-t 'terminal-emulator'] [-p port-number] [-dumb]
            [-s 'shell'] [-v 'env-var' ...]
```

* **`-t 'terminal-emulator'`**

  Specify the command line of a terminal emulator to execute. This format is the same as `TERM` in the configuration file. The command line should be enclosed in quotes to include spaces.

* **`-p port-number`**

  Instead of executing a terminal emulator, try connection to this port number of localhost. It is considered another program uses `-p` option to use Cygwin via `cygterm.exe`.

* **`-dumb`**

  Suppress the TELNET options negotiation. And ignore any TELNET commands sent from terminal side. The environment variable `TERM` is set to `dumb` on the shell side.

* **`-s 'shell'`**

  Specify the command line of a shell on Cygwin to execute. This format is the same as `SHELL` in the configuration file. The command line should be enclosed in quotes to include spaces. Any command can be specified even if a non-shell command.

* **`-v 'env-var'`**

  Specify the environment variable to be set when starting the shell. This format is the same as `ENV_X` in the configuration file. The expression should be enclosed in quotes to include spaces. One or more `-v` options are available.

---

* The terminal emulator or connection port number, and the shell on Cygwin, these need to be specified at least. If these are given in the command line, `cygterm.exe` can be run without configuration file `cygterm.cfg`.
* `cygterm.exe` is an Win32 application which uses `cygwin1.dll`. It can be run from Cygwin command line or a shortcut on Windows.

> It is necessary the Windows environment variable `PATH` includes a directory path of `cygwin1.dll` (normally `Cygwin-root\bin`) to be run from Windows.

## Notes

> **Attention in TeraTerm**  
> If your terminal emulator is TeraTerm be careful not to save `[Setup][Save setup]` in the situation that it was started by `cygterm.exe`. Otherwise telnet port number of TCP/IP is saved but 23 you will be confused by connection failure when you normally run TeraTerm to do telnet. In that case it will be recovered by saving the setting with specifying TCP/IP Port# 23.

## Tested On

As of 2017-Mar, CygTerm has been tested in the following environments.

* Cygwin 64bit 2.7 (`/bin/bash`)
* Windows 10 64bit
* TeraTermPro 4.87

Send bug reports, suggestions, etc. to <nsym@dd.iij4u.or.jp>.

## Changes

* **v1.08a (2017/03/31)**
  * Makefile: Add gcc compiler option `-D_GNU_SOURCE`.
  * `cygterm_here.reg`: sample registory file for explorer right-button click.

* **v1.08 (2015/08/16)**
  * Added `WILL ECHO` to TELNET negotiation to suppress line-at-a-time action of the terminal emulator.
  * Fixed to set `TERM` environment variable correctly.
  * Using `const` on read-only `char*` variables. (turn off the gcc Warning)
  * Modified `cygterm.cfg` (sample configuration)
    * Added `/T=1` option to teraterm commandline.
    * Changed the path of teraterm to `C:\Program Files (x86)\...`

* **v1.07 (2006/11/26)**
  * Avoid `WinMainCRTStartup()` redefinition error with gcc 3.4.
  * Give an output gap for keyboard interrupt.

* **v1.06 (2004/01/24)**
  * The following command line options were added:
    * `-t 'terminal-emulator'` (specifies the terminal emulator)
    * `-p port-number` (specifies the port# to connect)
    * `-dumb` (specifies dumb terminal mode)
    * `-s 'shell'` (specifies the shell)
    * `-v 'env-var'` (specifies environment variables)
  * Fixed to fail in `make install` if `BINDIR` was not found.
  * `cygterm.cc` and `README.txt` were changed to English version.

* **v1.05 (2003/01/14)**
  * Fixed to transmit Ctrl+SPACE (NUL). The NUL character was not able to be transmitted even if Ctrl+SPACE was typed, because it was ignored simply as an way to handle the newline CR+NUL.

* **v1.04 (2002/12/08)**
  * Changed to display error messages for failure to execute a terminal emulator or a shell.
  * Makefile was changed.
    * Do not overwrite `cygterm.cfg` when `make install`.
    * Add the gcc option `-fno-exceptions` against the GCC-3 link error.

* **v1.03 (2002/07/24)**
  * Fixed to convert terminal type into lower-case when cygterm received it from a terminal emulator. Because some upper-case values such as `ANSI` `VT100` of the environment variable `TERM` might not be found in terminfo depending on the kind of terminal emulator. (Windows 2000 `telnet.exe`, etc)

* **v1.02 (2002/07/22)**
  * Fix to be able to start a terminal emulator even if it was a console application. (Windows 2000 `telnet.exe`, etc. There was a mistake in calling `CreateProcess()`)
  * Fixed to suppress duplicate newline on a shell by canceling LF when a terminal emulator sent CR+LF. (Windows 98 `telnet.exe`, etc)
  * Embedded the version number in `cygterm.exe` executable code. (How to check: `$ strings cygterm.exe | grep version`)

* **v1.01 (2002/07/19)**
  * Fixed that cygterm did not work with zsh or tcsh. Input was blocked when zsh or tcsh started, because the approach to open the pseudo terminal was not good.

* **v1.00 (2000/12/17)**
  * The initial version was released.
