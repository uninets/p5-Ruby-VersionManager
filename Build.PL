use 5.010;
use feature 'say';
use warnings;

use lib 'lib';
use Ruby::VersionManager::Version;
use Module::Build;
use Getopt::Long qw(:config pass_through);

my $install = 0;
my $dist    = 0;
my $v = Ruby::VersionManager::Version->new;
my @script_files = grep { -f and ! -d } glob 'script/rvm.pl';
say for @script_files;

GetOptions(
    'install' => \$install,
    'dist'    => \$dist,
);

my $builder = Module::Build->new(
    module_name         => 'Ruby::VersionManager',
    license             => 'perl',
    dist_abstract       => 'Manage ruby versions',
    dist_author         => q{mugen Kenichi <mugen.kenichi@uninets.eu>},
    dist_version_from   => 'lib/Ruby/VersionManager/Version.pm',
    build_requires => {
        'Test::More' => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    requires => {
        'perl' => 5.010,
        'YAML' => 0,
        'Moo'  => 0,
        'Cwd'  => 0,
        'LWP'  => 0,
        'LWP::Simple' => 0,
        'File::Path'  => 0,
    },
    add_to_cleanup      => [ 'Ruby-VersionManager-* Build _build MYMETA.*' ],
    create_makefile_pl => 'traditional',

    meta_add => {
        no_index => {
            directory => ['t'],
        },
        version => $v->get,
        release_status => 'unstable',
    },
    script_files => [@script_files],
    meta_merge => {
        provides => {
            'Ruby::VersionManager' => {
                file => 'lib/Ruby/VersionManager.pm',
                version => $v->get,
            },
            'Ruby::VersionManager::Config' => {
                file => 'lib/Ruby/VersionManager/Config.pm',
                version => $v->get,
            },
            'Ruby::VersionManager::Version' => {
                file => 'lib/Ruby/VersionManager/Version.pm',
                version => $v->get,
            },
        },
    },

);

if ($dist) {
    $builder->dispatch('build');
    $builder->dispatch('test');
    $builder->dispatch('distmeta');
    $builder->dispatch('dist');
}

if ($install) {
    $builder->dispatch('build');
    $builder->dispatch('test', verbose => 1);
    $builder->dispatch('install');
}

$builder->create_build_script();
