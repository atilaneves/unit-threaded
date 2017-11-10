# -*- mode: python; -*-

project(
    'unit-threaded',
    'd',
    version: '0.7.32',
    default_options: ['buildtype=release'],
)

main_sources =  [
    'source/unit_threaded/asserts.d',
    'source/unit_threaded/attrs.d',
    'source/unit_threaded/dub.d',
    'source/unit_threaded/factory.d',
    'source/unit_threaded/integration.d',
    'source/unit_threaded/io.d',
    'source/unit_threaded/light.d',
    'source/unit_threaded/meta.d',
    'source/unit_threaded/mock.d',
    'source/unit_threaded/options.d',
    'source/unit_threaded/package.d',
    'source/unit_threaded/property.d',
    'source/unit_threaded/reflection.d',
    'source/unit_threaded/runner.d',
    'source/unit_threaded/runtime.d',
    'source/unit_threaded/should.d',
    'source/unit_threaded/testcase.d',
    'source/unit_threaded/testsuite.d',
    'source/unit_threaded/uda.d',
]

randomized_sources = [
    'source/unit_threaded/randomized/benchmark.d',
    'source/unit_threaded/randomized/gen.d',
    'source/unit_threaded/randomized/package.d',
    'source/unit_threaded/randomized/random.d',
]

inc_dirs = [
    include_directories('source'),
]

shared_library(
    meson.project_name(),
    main_sources + randomized_sources,
    include_directories: inc_dirs,
    version: meson.project_version(),
    soversion: '0',
    install: true,
)

static_library(
    meson.project_name(),
    main_sources + randomized_sources,
    include_directories: inc_dirs,
    install: true,
)

foreach item: main_sources
    install_data(item, install_dir: get_option('prefix') + '/include/d/unit_threaded')
endforeach

foreach item: randomized_sources
    install_data(item, install_dir: get_option('prefix') + '/include/d/unit_threaded/randomized')
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

#testExecutable = executable(
#    'unit-threaded-test',
#    main_sources + randomized_sources,
#    include_directories: inc_dirs,
#    d_args: ['-unittest'],
#    link_args: ['--main'],
#)

#test('all tests', testExecutable)
