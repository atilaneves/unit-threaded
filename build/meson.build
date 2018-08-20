# -*- mode: python; -*-

project(
    'unit-threaded',
    'd',
    version: '0.7.51',
    meson_version: '>=0.41',
    default_options: ['buildtype=release'],
)

main_sources = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls source/unit_threaded/*.d').stdout().split()
randomized_sources = run_command('sh', '-c', 'cd $MESON_SOURCE_ROOT && ls source/unit_threaded/randomized/*.d').stdout().split()

install_headers(main_sources, subdir: 'd/unit_threaded')
install_headers(randomized_sources, subdir: 'd/unit_threaded/randomized')

include_dirs = [include_directories('source/')]

lib = library(
    meson.project_name(),
    main_sources + randomized_sources,
    include_directories: include_dirs,
    version: meson.project_version(),
    soversion: '0',
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

executable(
    'gen-ut-main',
    'gen/gen_ut_main.d',
    include_directories: include_dirs,
    link_with: lib,
    link_args: ['-link-defaultlib-shared'],
    install: true,
)

unitthreaded_dep = declare_dependency(
    link_with: lib,
    include_directories: [include_dirs],
)
