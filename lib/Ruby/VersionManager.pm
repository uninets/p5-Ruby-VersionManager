package Ruby::VersionManager;

use 5.010;
use strict;
use feature 'say';
use warnings;
use autodie;

use Moo;
use YAML;
use LWP::UserAgent;
use HTTP::Request;

has rootdir => ( is => 'rw' );
has ruby_version => ( is => 'rw' );
has rubygems_version => (is => 'rw' );
has available_rubies => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    $self->_make_base or die;
    $self->_check_db or die;
}

sub _make_base {
    my ($self) = @_;

    $self->rootdir($ENV{'HOME'} . '/.ruby_vmanager') unless $self->rootdir;

    if (not -d $self->rootdir){
        say "root directory for installation not found.\nbootstraping to " . $self->rootdir;
        mkdir $self->rootdir or return 0;
        mkdir $self->rootdir . '/bin' or return 0;
        mkdir $self->rootdir . '/source' or return 0;
        mkdir $self->rootdir . '/var' or return 0;
        mkdir $self->rootdir . '/gemsets' or return 0;
        mkdir $self->rootdir . '/rubies' or return 0;
    }

    return 1;

}

sub _check_db {
    my ($self) = @_;

    $self->update_db unless -f $self->rootdir . '/var/db.yml';
    $self->available_rubies(YAML::LoadFile($self->rootdir . '/var/db.yml'));

}

sub update_db {
    my ($self) = @_;

    my @versions = (
        1.8,
        1.9,
    );

    my $rubies = {};

    for my $version (@versions){
        my $ruby_ftp = 'ftp://ftp.ruby-lang.org/pub/ruby/' . $version;
        my $req = HTTP::Request->new(GET => $ruby_ftp);

        my $ua = LWP::UserAgent->new;
        $ua->agent("Ruby::VersionManager/0.01");

        my $res = $ua->request($req);

        if ($res->is_success){
            $rubies->{$version} = [];
            for (grep { $_ ~~ /ruby-.*\.tar\.bz2/ } split '\n', $res->content){
                push @{$rubies->{$version}}, (split ' ', $_)[-1];
            }
        }
    }

    die "Did not get any data from ftp.ruby-lang.org" unless %$rubies;

    YAML::DumpFile($self->rootdir . '/var/db.yml', $rubies);

}

sub list {
    my ($self) = @_;

    $self->_check_db or die;
    my %rubies = %{$self->available_rubies};

    for (keys %rubies){
        say "Version $_:";
        for (@{$rubies{$_}}){
            (my $ruby = $_) =~ s/(.*)\.tar\.bz2/$1/;
            say "\t$ruby";
        }
    }
}
