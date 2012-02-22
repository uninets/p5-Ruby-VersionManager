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
use LWP::Simple;
use Cwd qw'abs_path cwd';

use Ruby::VersionManager::Version;

has rootdir => ( is => 'rw' );
has ruby_version => ( is => 'rw' );
has major_version => ( is => 'rw' );
has rubygems_version => ( is => 'rw' );
has available_rubies => ( is => 'rw' );
has agent_string => ( is => 'rw' );
has archive_type => ( is => 'rw' );
has gemset => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    my $v = Ruby::VersionManager::Version->new;

    $self->agent_string('Ruby::VersionManager/' . $v->get);
    $self->_make_base or die;
    $self->_check_db or die;
    $self->archive_type('.tar.bz2');
    $self->gemset('default') unless $self->gemset;
}

sub _make_base {
    my ($self) = @_;

    $self->rootdir($ENV{'HOME'} . '/.ruby_vmanager') unless $self->rootdir;

    if (not -d $self->rootdir){
        say "root directory for installation not found.\nbootstraping to " . $self->rootdir;
        mkdir $self->rootdir;
        mkdir $self->rootdir . '/bin';
        mkdir $self->rootdir . '/source';
        mkdir $self->rootdir . '/var';
        mkdir $self->rootdir . '/gemsets';
        mkdir $self->rootdir . '/rubies';
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
        $ua->agent($self->agent_string);

        my $res = $ua->request($req);

        if ($res->is_success){
            $rubies->{$version} = [];
            for (grep { $_ ~~ /ruby-.*\.tar\.bz2/ } split '\n', $res->content){
                my $at = $self->archive_type;
                (my $ruby = $_) =~ s/(.*)$at/$1/;
                push @{$rubies->{$version}}, (split ' ', $ruby)[-1];
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
        my @rubies = $self->_sort_rubies( $rubies{$_} );
        for (@rubies){
            my $at = $self->archive_type;
            (my $ruby = $_) =~ s/(.*)$at/$1/;
            say "\t$ruby";
        }
    }
}

sub _sort_rubies {
    my ($self, $rubies) = @_;

    my @sorted = ();
    my $major_versions;

    for (@$rubies){
        my (undef, $major, $patchlevel) = split '-', $_;
        $major_versions->{$major} = [] unless $major_versions->{$major};
        push @{$major_versions->{$major}}, $patchlevel;
    }

    for my $version (sort { $a cmp $b } keys %{$major_versions}){
        my @patchlevels = grep {
                                defined $_
                                &&
                                $_ =~ /p\d{1,3}/
                          } @{$major_versions->{$version}};
        my @pre = grep {
                        defined $_
                        &&
                        $_ =~ /preview\d{0,1}|rc\d{0,1}/
                  } @{$major_versions->{$version}};
        my @old = grep {
                        defined $_
                        &&
                        $_ =~ /^\d/
                  } @{$major_versions->{$version}};

        my @numeric_levels;
        for my $level (@patchlevels){
            (my $num = $level) =~ s/p(\d+)/$1/;
            push @numeric_levels, $num;
        }

        @patchlevels = ();
        for (sort { $a <=> $b } @numeric_levels){
            push @patchlevels, 'p' . $_;
        }

        for ( (sort { $a cmp $b } @old), @patchlevels, (sort { $a cmp $b } @pre) ){
            push @sorted, "ruby-$version-$_";
        }

    }

    return @sorted;
}

sub _guess_version {
    my ($self) = @_;

    my @rubies = ();
    my $req_version = $self->ruby_version;
    # 1.8 or 1.9?
    for my $major_version (keys %{$self->available_rubies}){
        if ($req_version =~ /$major_version/){
            for my $ruby (@{$self->available_rubies->{$major_version}}){
                if ($ruby =~ /$req_version/){

                    my $at = $self->archive_type;
                    ($ruby = $ruby) =~ s/(.*)$at/$1/;

                    if ($ruby eq $req_version){
                        push @rubies, $ruby;
                        last;
                    }
                    elsif ($ruby =~ /preview|rc\d?+/){
                        next;
                    }

                    push @rubies, $ruby;
                }
            }
        }
    }

    my $guess = ($self->_sort_rubies([@rubies]))[-1];

    if (not $guess){
        say "No matching version found. Valid versions:";
        $self->list;

        exit 1;
    }

    return $guess;
}

sub install {
    my ($self) = @_;

    $self->ruby_version($self->_guess_version);
    (my $major_version = $self->ruby_version) =~ s/ruby-(\d\.\d).*/$1/;
    $self->major_version($major_version);

    $self->_fetch_ruby;
    $self->_unpack_ruby;
    $self->_make_install;

    $self->_setup_environment;
    $self->_install_rubygems;

}

sub _unpack_ruby {
    my ($self) = @_;

    system 'tar xf ' . $self->rootdir . '/source/'
            . $self->ruby_version . $self->archive_type
            . ' -C  '
            . $self->rootdir . '/source/';

    return 1;
}

sub _make_install {
    my ($self) = @_;

    my $prefix = $self->rootdir . '/rubies/' . $self->major_version . '/' . $self->ruby_version;

    my $cwd = cwd();

    chdir $self->rootdir . '/source/' . $self->ruby_version;

    system "./configure --enable-pthread --enable-shared --prefix=$prefix && make && make install";

    chdir $cwd;

    return 1;
}

sub _setup_environment {
    my ($self) = @_;

    $ENV{RUBY_VERSION} = $self->ruby_version;
    $ENV{GEM_PATH} = abs_path($self->rootdir) . '/gemsets/'
        . $self->major_version
        . '/'
        . $self->ruby_version
        . '/'
        . $self->gemset;
    $ENV{GEM_HOME} = abs_path($self->rootdir) . '/gemsets/'
        . $self->major_version
        . '/'
        . $self->ruby_version
        . '/'
        . $self->gemset;
    $ENV{MY_RUBY_HOME} = abs_path($self->rootdir)
        . '/'
        . $self->major_version
        . '/'
        . $self->ruby_version;
    $ENV{PATH} = abs_path($self->rootdir)
        . '/rubies/'
        . $self->major_version
        . '/'
        . $self->ruby_version
        . '/bin'
        . ':'
        . abs_path($self->rootdir)
        . '/gemsets/'
        . $self->major_version
        . '/'
        . $self->ruby_version
        . '/'
        . $self->gemset
        . '/bin'
        . ':'
        . $ENV{PATH};

    open my $rcfile, '>', $self->rootdir . '/var/ruby_vmanager.rc';
    say $rcfile 'export RUBY_VERSION=' . $self->ruby_version;
    say $rcfile 'export GEM_PATH=' . $ENV{GEM_PATH};
    say $rcfile 'export GEM_HOME=' . $ENV{GEM_HOME};
    say $rcfile 'export MY_RUBY_HOME=' . $ENV{MY_RUBY_HOME};
    say $rcfile 'export PATH=' . abs_path($self->rootdir)
        . '/rubies/'
        . $self->major_version
        . '/'
        . $self->ruby_version
        . '/bin'
        . ':'
        . abs_path($self->rootdir)
        . '/gemsets/'
        . $self->major_version
        . '/'
        . $self->ruby_version
        . '/'
        . $self->gemset
        . '/bin'
        . ':$PATH';

    close $rcfile;
}

sub _fetch_ruby {
    my ($self) = @_;

    my $url = 'ftp://ftp.ruby-lang.org/pub/ruby/'
              . $self->major_version
              . '/'
              . $self->ruby_version
              . $self->archive_type;

    my $file = $self->rootdir . '/source/' . $self->ruby_version . $self->archive_type;

    if ( -f $file ){
        return 1
    }

    my $result = LWP::Simple::getstore($url, $file);

    die if $result != 200;

    return 1;

}

sub _install_rubygems {
    my ($self) = @_;

    unless (-f $ENV{MY_RUBY_HOME} . '/bin/gem'){
        my $url = 'http://rubyforge.org/frs/download.php/70696/rubygems-1.3.7.tgz';
        my $file = $self->rootdir . '/source/rubygems-1.3.7.tgz';

        if ( -f $file ){
            return 1;
        }

        my $result = LWP::Simple::getstore($url, $file);

        die if $result != 200;

        system 'tar xf ' . $file . ' -C ' . $self->rootdir . '/source/';

        my $cwd = cwd();

        chdir $self->rootdir . '/source/rubygems-1.3.7';
        system 'ruby setup.rb';
    }

    return 1;
}

__END__

=head1 NAME

Ruby::VersionManager

=head1 WARNING

This is an unstable development release not ready for production!

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

The Ruby::VersionManager Module will provide a subset of the bash rvm.

=head1 INSTALL RUBY

It is recommended to use Ruby::VersionManager with local::lib to avoid interference with possibly installed system ruby.
Ruby::VersionManager comes with a script rvm.pl with following options.

=head2 list

List available ruby versions.

    rvm.pl list

=head2 updatedb

Update database of available ruby versions.

    rvm.pl updatedb

=head2 install

Install a ruby version. If no version is given the latest stable release will be installed.
The program tries to guess the correct version from the provided string. It should at least match the major release.
If you need to install a preview or rc version you will have to provide the full exact version.

Latest ruby

    rvm.pl install

Latest ruby-1.8

    rvm.pl install 1.8

Install preview

    rvm.pl install ruby-1.9.3-preview1


=head1 LIMITATIONS AND TODO

Currently Ruby::VersionManager is only running on Linux with bash installed.
Support of gemsets and uninstall needs to be added.

=head1 AUTHOR

Mugen Kenichi, C<< <mugen.kenichi at uninets.eu> >>

=head1 BUGS

Report bugs at:

=over 2

=item * Ruby::VersionManager issue tracker

L<https://github.com/mugenken/p5-Ruby-VersionManager/issues>

=item * support at uninets.eu

C<< <mugen.kenichi at uninets.eu> >>

=back

=head1 SUPPORT

=over 2

=item * Technical support

C<< <mugen.kenichi at uninets.eu> >>

=back

=cut

