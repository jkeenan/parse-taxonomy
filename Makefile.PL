use ExtUtils::MakeMaker;
require 5.006;

my $mm_ver = ExtUtils::MakeMaker->VERSION;

WriteMakefile(
    NAME            => 'Parse::File::Taxonomy',
    VERSION_FROM    => 'lib/Parse/File/Taxonomy.pm',
    ABSTRACT_FROM   => 'lib/Parse/File/Taxonomy.pm',
    AUTHOR          => 'James E Keenan (jkeenan@cpan.org>)',
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' )
                    =>  {
                            'Test::Simple' => 0.10,
                        },
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage => 'http://thenceforward.net/perl/modules/Parse-File-Taxonomy/',
            repository => {
                url => 'https://github.com/jkeenan/parse-file-taxonomy.git',
                web => 'https://github.com/jkeenan/parse-file-taxonomy',
                type => 'git',
            },
            bugtracker => {
                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Parse-File-Taxonomy',
            },
        },
    })),
    PREREQ_PM    => {
                     'Text::CSV'    => 0,
                     'Carp'         => 0,
                     'Scalar::Util' => 0,
    },
);
