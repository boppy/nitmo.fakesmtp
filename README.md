# nitmo fakeSMTP

Monit, by default, sends out mails to notify about the configured actions. There also is the possibility to execute a script rather than send an email, but there are some limitations in this approach (no reminder for example). So the idea was to build a STMP Server as tiny as possible and to have as little dependencies as possible (ends up in < 2k Byte of code).

The nitmo fakeSMTP is therefore written totally in bash with only using (1) binaries that should be at hand even on an Alpine or any other \*nix System (*PLEASE* file an issue if not).

*HANDLE WITH CARE*: Its **solely purpose** is to receive Monit mails! It is not meant to be a SMTP drop-in replacement. It does not even know basic SMTP-Commands (like `noop` or `rst`), because Monit doesn't make use of them.


## Dependencies

* od
* tr
* sed
* Socket handler *(see examples for systemd, inetd/openbsd-inetd, and xinetd in Installation section)*


## Installation
*I assume that nobody who uses monit has to be introduced to using `sudo`, `bash`, and a text editor.*

* Make the `nitmo_fakesmtp.sh` executable (`chmod +x nitmo_fakesmtp.sh`) and remember its path (`/usr/local/bin` or `/usr/local/sbin` might be a good place if you do not want to remember the path).
* Make the script listen to a port
  * With **systemd** (recommended)
    * Copy [nitmo_fakesmtp.socket](nitmo_fakesmtp.socket) and [nitmo_fakesmtp@.service](nitmo_fakesmtp@.service) to `/etc/systemd/system`
    * Change the **ExecStart** in `nitmo_fakesmtp@.service` to the correct path of your executable (skip this if the path is inside `$PATH`)
    * Change the **ListenStream** in `nitmo_fakesmtp.socket` to the port your want your fakeSMTP to listen to (skip this if port 2525 is okay for you). **WARNING**: *Do not remove* the `127.0.0.1` part since the fakeSMTP would then be open to connections from the internet!
    * Enable the socket with `systemctl enable nitmo_fakeSMTP.socket`

  * With **inetd** (not tested, ***creates open relay if used unaltered!!!***)
    * Add the following line to your `/etc/inetd.conf`:
    * `2525   stream    tcp    nowait    root    /path/to/fakeSMTP.php`
    * **Take security steps because inetd cannot (by default) limit connections by itself. See tcpd or similar to protect against installing an open relay!**
    * Sharing your installation steps by providing an issue or pull request is greatly appreciated.
  
  * With **xinetd** (not tested, ***creates open relay if used unaltered!!!***)
    * Convert the inetd example with `xconv.pl` (previously `itox`) that should be provided with xinetd:
    * `xconv.pl <<< "2525   stream    tcp    nowait    root    /path/to/fakeSMTP.php" > monit_fakeSMTP.xinetd`
    * **Take security steps because this config does not limit connections. See tcpd or similar to protect against installing an open relay!**
    * Sharing your installation steps by providing an issue or pull request is greatly appreciated.

## Notification examples

The `receiver.sh` includes examples on calling binaries.

* *Be aware* that the script `trim`s the lines. So any `\r|^M` will be removed. If you like to forward to email (ie. `sendmail`) your have to add `\r` at least to the header lines!
* An example of dropping mails is included
* An example of logging the mails to files is included
* Calling binary telegram-send (see pip, requires Python)
* Calling a php script (might require php... ;-))
* An example of connecting to slack: https://peteris.rocks/blog/monit-configuration-with-slack/
