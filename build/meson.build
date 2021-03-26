# -*- mode: python; -*-

project(
    'unit-threaded',
    'd',
    version: '1.0.14',
    meson_version: '>=0.48',
    default_options: ['buildtype=release'],
)

main_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls ../source/unit_threaded/*.d').stdout().split()
assertions_subpackage_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls ../subpackages/assertions/source/unit_threaded/*.d').stdout().split()
exception_subpackage_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls ../subpackages/exception/source/unit_threaded/*.d').stdout().split()
from_subpackage_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls ../subpackages/from/source/unit_threaded/*.d').stdout().split()
integration_subpackage_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls ../subpackages/integration/source/unit_threaded/*.d').stdout().split()
mocks_subpackage_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls ../subpackages/mocks/source/unit_threaded/*.d').stdout().split()
property_subpackage_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls ../subpackages/property/source/unit_threaded/*.d').stdout().split()
property_subpackage_randomized_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls ../subpackages/property/source/unit_threaded/randomized/*.d').stdout().split()
runner_subpackage_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls ../subpackages/runner/source/unit_threaded/runner/*.d').stdout().split()

# Treat the single source file packages differently to those with multiple files including a package.d file.
install_headers(main_source, subdir: 'd/unit_threaded')
install_headers(assertions_subpackage_source, subdir: 'd/unit_threaded')  # Single file package.
install_headers(exception_subpackage_source, subdir: 'd/unit_threaded')  # Single file package.
install_headers(from_subpackage_source, subdir: 'd/unit_threaded')  # Single file package.
install_headers(integration_subpackage_source, subdir: 'd/unit_threaded')  # Single file package.
install_headers(mocks_subpackage_source, subdir: 'd/unit_threaded')  # Single file package.
install_headers(property_subpackage_source, subdir: 'd/unit_threaded')  # Single file package.
install_headers(property_subpackage_randomized_source, subdir: 'd/unit_threaded/randomized')
install_headers(runner_subpackage_source, subdir: 'd/unit_threaded/runner')

include_dirs = [
    include_directories('../source/'),
    include_directories('../subpackages/assertions/source/'),
    include_directories('../subpackages/exception/source/'),
    include_directories('../subpackages/from/source/'),
    include_directories('../subpackages/integration/source/'),
    include_directories('../subpackages/mocks/source/'),
    include_directories('../subpackages/property/source/'),
    include_directories('../subpackages/runner/source/'),
]

lib = library(
    meson.project_name(),
    main_source +
        assertions_subpackage_source +
        exception_subpackage_source +
        from_subpackage_source +
        integration_subpackage_source +
        mocks_subpackage_source +
        property_subpackage_source +
        property_subpackage_randomized_source +
        runner_subpackage_source,
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

gen_ut_main_runtime_source = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls ../gen/source/unit_threaded/runtime/*.d').stdout().split()

executable(
    'gen-ut-main',
    ['../gen/gen_ut_main.d'] + gen_ut_main_runtime_source,
    include_directories: include_dirs + [include_directories('../gen/source')],
    link_with: lib,
    link_args: ['-link-defaultlib-shared'],
    install: true,
)

unitthreaded_dep = declare_dependency(
    link_with: lib,
    include_directories: [include_dirs],
)
