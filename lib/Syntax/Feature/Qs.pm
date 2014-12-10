use strict;

package Syntax::Feature::Qs;
$Syntax::Feature::Qs::VERSION = '0.0101';
use Devel::Declare 0.006007 ();
use B::Hooks::EndOfScope 0.09;
use Sub::Install 0.925 qw/install_sub/;

use aliased 'Devel::Declare::Context::Simple', 'Context';

use syntax qw|simple/v2|;
use namespace::clean;

my %quote_op = qw(qs q qqs qq);
my @new_ops = keys %quote_op;

method install($class: %args) {
    my $target = $args{'into'};

    Devel::Declare->setup_for($target => {
        map {
            my $name = $_;
            ($name => {
                const => sub {
                    my $context = Context->new;
                    $context->init(@_);
                    return $class->_transform($name, $context);
                },
            });
        } @new_ops
    });
    foreach my $name (@new_ops) {
        install_sub {
            into => $target,
            as => $name,
            code => $class->_run_callback,
        };
    }
    on_scope_end {
        namespace::clean->clean_subroutines($target, @new_ops);
    };
    return 1;
}

method _run_callback {
    return sub ($) {
        my $string = shift;
        $string =~ s{^\h+|\h+$}{}gms;
        return $string;
    };
}

method _transform ($class: $name, $ctx) {
    $ctx->skip_declarator;
    my $length = Devel::Declare::toke_scan_str($ctx->offset);
    my $string = Devel::Declare::get_lex_stuff;
    Devel::Declare::clear_lex_stuff;
    my $linestr = $ctx->get_linestr;
    my $quoted = substr $linestr, $ctx->offset, $length;
    my $spaced = '';
    $quoted =~ m{^(\s*)}sm;
    $spaced = $1;
    my $new = sprintf '(%s)', join '',
        $quote_op{$name},
        $spaced,
        substr($quoted, length($spaced), 1),
        $string,
        substr($quoted, -1, 1);
    substr($linestr, $ctx->offset, $length) = $new;
    $ctx->set_linestr($linestr);
    return 1;
}

1;

__END__

=encoding utf-8

=head1 NAME

Syntax::Feature::Qs - Trim whitespace from all lines

=head1 SYNOPSIS

    use syntax 'qs';

    say qs{
        Multi line
        string
    };

    # is exactly the same as

    say q{
    Multi line
    string
    };

=head1 DESCRIPTION

This is a syntax extension to be used with L<syntax>.

It provides two quote-like operators, C<qs> and C<qqs>. They are drop-in replacements for C<q> and C<qq>, respectively.

Their purpose is to automatically trim leading and trailing horizontal whitespace on every line. They do not remove empty lines.


=head1 SEE ALSO

=over 4

=item L<Syntax::Feature::Ql> (which served as a base for this)

=item L<Syntax::Feature::Qi>

=item L<syntax>

=back

=head1 AUTHOR

Erik Carlsson E<lt>info@code301.comE<gt>

=head1 COPYRIGHT

Copyright 2014 - Erik Carlsson

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
