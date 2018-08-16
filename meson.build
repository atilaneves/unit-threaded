# -*- mode: python; -*-

project(
    'unit-threaded',
    'd',
    version: '0.8.0',
    meson_version: '>=0.41',
    default_options: ['buildtype=release'],
)

main_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls source/unit_threaded/*.d').stdout().split()
from_subpackage_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls from/source/unit_threaded/*.d').stdout().split()
exception_subpackage_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls exception/source/unit_threaded/*.d').stdout().split()
assertions_subpackage_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls assertions/source/unit_threaded/*.d').stdout().split()
runner_subpackage_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls runner/source/unit_threaded/runner*.d').stdout().split()
mocks_subpackage_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls mocks/source/unit_threaded/*.d').stdout().split()
integration_subpackage_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls integration/source/unit_threaded/*.d').stdout().split()
property_subpackage_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls property/source/unit_threaded/*.d').stdout().split()
property_subpackage_randomized_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls property/source/unit_threaded/randomized/*.d').stdout().split()

install_headers(main_source, subdir: 'd/unit_threaded')
install_headers(from_subpackage_source, subdir: 'd/unit_threaded/from')
install_headers(exception_subpackage_source, subdir: 'd/unit_threaded/exception')
install_headers(assertions_subpackage_source, subdir: 'd/unit_threaded/assertions')
install_headers(runner_subpackage_source, subdir: 'd/unit_threaded/runner')
install_headers(mocks_subpackage_source, subdir: 'd/unit_threaded/mocks')
install_headers(integration_subpackage_source, subdir: 'd/unit_threaded/integration')
install_headers(property_subpackage_source, subdir: 'd/unit_threaded/property')
install_headers(property_subpackage_randomized_source, subdir: 'd/unit_threaded/property/randomized')

include_dirs = [
    include_directories('source/'),
    include_directories('from/source/'),
    include_directories('exception/source/'),
    include_directories('assertions/source/'),
    include_directories('runner/source/'),
    include_directories('mocks/source/'),
    include_directories('integration/source/'),
    include_directories('property/source/'),
]

lib = library(
    meson.project_name(),
    main_source +
        from_subpackage_source +
        exception_subpackage_source +
        assertions_subpackage_source +
        runner_subpackage_source +
        mocks_subpackage_source +
        integration_subpackage_source +
        property_subpackage_source +
        property_subpackage_randomized_source,
    include_directories: include_dirs,
    version: meson.project_version(),
    pic: true,
    install: true,
)

pkgconfig = import('pkgconfig')
pkgconfig.generate(
    name: meson.project_name(),
    libraries: lib,
    subdirs: 'd/',
    version: meson.project_version(),
    description: 'Advanced multi-threaded unit testing framework with minimal to no boilerplate using built-in unittest blocks.',
)

gen_ut_main_runtime_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls gen/source/unit_threaded/runtime/*.d').stdout().split()

executable(
    'gen-ut-main',
    ['gen/gen_ut_main.d'] + gen_ut_main_runtime_source,
    include_directories: include_dirs + [include_directories('gen/source')],
    link_with: lib,
    link_args: ['-link-defaultlib-shared'],
    install: true,
)

unitthreaded_dep = declare_dependency(
    link_with: lib,
    include_directories: [include_dirs],
)
