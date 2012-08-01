package Ruby::VersionManager::Gem;

use 5.010;
use Moo;
use strict;
use feature 'say';
use warnings;
use Data::Dumper;

has gem_list => ( is => 'rw' );
has dispatch => ( is => 'rw' );
has options  => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    my $dispatch = { reinstall => $self->can('_reinstall'), };

    $self->dispatch($dispatch);

    return 1;
}

sub run_action {
    my ( $self, $action, @options ) = @_;

    if ( exists $self->dispatch->{$action} ) {
        $self->options(@options);
        $self->dispatch->{$action}->($self);
    }
    else {
        system 'gem ' . join ' ', ( $action, @options );
    }

    return 1;
}

sub _reinstall {
    my ($self) = @_;

    if ( defined $self->gem_list && -f $self->gem_list ) {
        my $gemlist = '';
        {
            local $/;
            open my $fh, '<', $self->gem_list;
            $gemlist = <$fh>;
            close $fh;
        }
        $self->gem_list( $self->_parse_gemlist($gemlist) );
    }
    elsif ( defined $self->options && -f ( $self->options )[0] ) {
        my $gemlist = '';
        {
            local $/;
            open my $fh, '<', ( $self->options )[0];
            $gemlist = <$fh>;
            close $fh;
        }
        $self->gem_list( $self->_parse_gemlist($gemlist) );
    }
    else {
        my $gemlist = qx[gem list];
        $self->gem_list( $self->_parse_gemlist($gemlist) );
    }

    $self->_install_gems( $self->gem_list, { nodeps => 1 } );
}

sub _parse_gemlist {
    my ( $self, $gemlist ) = @_;

    my $gems = {};
    for my $line ( split /\n/, $gemlist ) {
        my ( $gem, $versions ) = $line =~ /
            ([-_\w]+)\s # capture gem name
            [(](
                (?:
                    (?:
                        (?:\d+\.)*\d+
                    )
                    ,?\s?
                )+
            )[)]/mxg;
        $gems->{$gem} = [ split ', ', $versions ] if defined $gem;
    }

    return $gems;
}

sub _install_gems {
    my ( $self, $gems, $opts ) = @_;

    for my $gem ( keys %$gems ) {
        for my $version ( @{ $gems->{$gem} } ) {
            my $cmd = "gem install $gem ";
            $cmd .= "-v=$version";
            if ( defined $opts && $opts->{'nodeps'} ) {
                $cmd .= " --ignore-dependencies";
            }

            my $output = qx[$cmd];
        }
    }

    return 1;
}

1;

