package Ruby::VersionManager::Config;

use 5.010;
use feature 'say';
use warnings;
use autodie;

use Moo;
use YAML;

has rootdir => ( is => 'rw' );
has ruby_version => ( is => 'rw' );
has rubygems_version => (is => 'rw' );

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


}

