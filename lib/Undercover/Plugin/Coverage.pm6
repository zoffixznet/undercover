unit class Undercover::Plugin::Coverage;
use MONKEY-SEE-NO-EVAL;
use HTTP::UserAgent;
use CoreHackers::Sourcery;

has $.executable-dir is required;
has $.core-hackers   is required;

method irc-to-me ($e where /^ ['cover' 'age'? ':'?]? \s+ $<code>=.+/) {
    my $code = ~$<code>;
    unless $e.host eq 'perl6/zoffix' | 'perl6.party' {
        is-safeish $code or return "Ehhh... I'm too scared to run that code.";
    }

    chdir $.executable-dir;
    my $p = run(
        :err,
        :out,  './perl6-m', '-I', $.core-hackers,
        '-e', qq:to/END/
            BEGIN \{
                \%*ENV<SOURCERY_SETTING>
                = '{$.executable-dir}gen/moar/CORE.setting';
            \};
            use CoreHackers::Sourcery;
            print "SUCCESS:\{sourcery( $code )[0]\}";
        END
    );
    my $result = $p.out.slurp-rest;
    my $merge = $result ~ "\nERR: " ~ $p.err.slurp-rest;
    return "Something's wrong: $merge.subst("\n", '␤', :g)"
        unless $result ~~ /^ 'SUCCESS'/;

    my ($file, $line) = $result.split(':')[1,2];
    my $url = "https://wtf.rakudo.party/SETTING__{$file.subst: :g, /\W/, '_'}.coverage.html#L$line";

    my $res = HTTP::UserAgent.new.get: $url;
    return "Failed to fetch coverage from $url [{$res.status-line}]"
        unless $res.is-success;

    return "Failed to figure out coverage status on $url"
        unless $res.content ~~ m{
            '<li' \s+ 'class="' $<status>=<[iuc]>
            '" id="L' $line '">' $<code>=\N+
        };

    my $status = $<status> eq 'u' ?? 'uncovered'
        !! $<status> eq 'c' ?? 'covered' !! 'incomplete';

    my $is-proto = so $<code> ~~ /^\s* 'proto' \s+/;

    return join ' ',
        ($status eq 'covered' ?? 'The code is hit during stresstest'
                              !! 'The code is NOT hit during stresstest'
        ),
        ('[WARNING: this line is a proto! Check individual multies]' if $is-proto),
        "See $url for details",
    ;
}

sub is-safeish ($code) {
    return if $code ~~ /<[;{]>/;
    return if $code.comb('(') != $code.comb(')');
    for <run shell qx EVAL> -> $danger {
        return if $code ~~ /«$danger»/
    }
    return True;
}
