#!/usr/bin/env perl6
use lib <
    /home/zoffix/CPANPRC/IRC-Client/lib
    /home/zoffix/services/lib/IRC-Client/lib
    lib
>;

use IRC::Client;
use Undercover::Plugin::Coverage;

class Undercover::Info {
    multi method irc-to-me ($ where /^\s* help \s*$/) {
        "Use cover: trigger with args to give to sourcery sub."
        ~ " e.g. cover: Int, 'base'. See"
        ~ " http://modules.perl6.org/dist/CoreHackers::Sourcery";
    }
    multi method irc-to-me ($ where /^\s* source \s*$/) {
        "See: https://github.com/zoffixznet/undercover";
    }

    multi method irc-to-me ($ where /'bot' \s* 'snack'/) { "om nom nom nom"; }
}

.run with IRC::Client.new:
    :nick<Undercover>,
    :username<zofbot-undercover>,
    :host(%*ENV<UNDERCOVER_IRC_HOST> // 'irc.freenode.net'),
    :channels( %*ENV<UNDERCOVER_DEBUG> ?? '#zofbot' !! |<#perl6  #perl6-dev  #zofbot>),
    :debug,
    :plugins(
        Undercover::Info.new,
        Undercover::Plugin::Coverage.new:
            :executable-dir(
                %*ENV<UNDERCOVER_EXE>
                    // '/home/zoffix/services/sourceable/perl6/'
            ),
            :core-hackers(
                %*ENV<UNDERCOVER_SOURCERY>
                    // '/home/zoffix/services/lib/CoreHackers-Sourcery/lib'
            )
    );
