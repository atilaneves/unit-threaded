# -*- mode: python; -*-

project(
    'unit-threaded',
    'd',
    version: '0.7.43',
    default_options: ['buildtype=release'],
)

main_sources = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls source/unit_threaded/*.d').stdout().split()
randomized_sources = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls source/unit_threaded/randomized/*.d').stdout().split()
tests_sources = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls source/unit_threaded/tests/*.d').stdout().split()

inc_dirs = [
    include_directories('source'),
]

unit_threaded = shared_library(
    meson.project_name(),
    main_sources + randomized_sources + tests_sources,
    include_directories: inc_dirs,
    version: meson.project_version(),
    soversion: '0',
    install: true,
)

static_library(
    meson.project_name(),
    main_sources + randomized_sources + tests_sources,
    include_directories: inc_dirs,
    install: true,
)

foreach item: main_sources
    install_data(item, install_dir: get_option('prefix') + '/include/d/unit_threaded')
endforeach

foreach item: randomized_sources
    install_data(item, install_dir: get_option('prefix') + '/include/d/unit_threaded/randomized')
endforeach

foreach item: tests_sources
    install_data(item, install_dir: get_option('prefix') + '/include/d/unit_threaded/tests')
endforeach

# The pkgconfig system produces C/C++ library flags which are of
# little use with ldc2, so must do things the hard way. :-(

pc_file_data = configuration_data()
pc_file_data.set('NAME', meson.project_name())
pc_file_data.set('VERSION', meson.project_version())
pc_file_data.set('DESCRIPTION', 'Advanced multi-threaded unit testing framework with minimal to no boilerplate using built-in unittest blocks.')
pc_file_data.set('LIBS', '-L-L${libdir} -L-l' + meson.project_name())
pc_file_data.set('CFLAGS', '-I${includedir}/d')
pc_file_data.set('PREFIX', get_option('prefix'))
pc_file = configure_file(configuration: pc_file_data, input: meson.project_name() + '.pc.in', output: meson.project_name() + '.pc')

install_data(pc_file, install_dir: 'share/pkgconfig')

executable(
    'gen-ut-main',
    'gen/gen_ut_main.d',
    include_directories: inc_dirs,
    link_with: unit_threaded,
    install: true,
)

# unit_threaded requires a unity build which Meson cannot do for D as yet (2017-11-10).

#testExecutable = executable(
#    'unit-threaded-test',
#    main_sources + randomized_sources + tests_sources,
#    include_directories: inc_dirs,
#    d_args: ['-unittest'],
#    link_args: ['--main'],
#)

#test('all tests', testExecutable)
