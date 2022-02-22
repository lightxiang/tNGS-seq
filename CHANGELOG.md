# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

## [Unreleased]

## [0.5.3] - 2020-07-31
### Added
- chinese name annotation in resistantGene
- add --length_required(fastp)

## [0.5.2] - 2020-07-24
### Changed
- update cmdb version to 20200724

## [0.5.1] - 2020-07-22
### Fixed
- memory usage

## [0.5.0] - 2020-07-21
### Added
- add resistant gene analysis

### Changed
- change the time directive and some labels of process

## [0.4.2] - 2020-06-24
### Added
- add dhost_tool parameter and lcf_score parameter

### Changed
- change the process HostAlign

### Fixed
- fix bug in prefetch data on cloud when the library DNA and RNA need analysed together


## [0.4.1] - 2020-06-19
### Added
- add a new parameter for LRM system

### Changed
- change the file prefix in Results folder

## [0.4.0] - 2020-06-09
### Added
- more items in the EXCEL output
- add --reads_to_process
- add display of the backgroud species
- add attention species and gene in the background excel

### Changed
- sort strategy of species
- rewrite reads pct

### Fixed
- lost the G type
- use the wrong column to filter the label
- label filter of System_background can not read abundance
- regex method

## [0.3.0] - 2020-05-18
### Added
- add sample library_type for process params/method self-adaptation
- add --rna_dedup and --rna_rrnarm for rna library
- add input/output table columns datatype description

## [0.2.0] - 2020-04-10
### Added
- add HostAlign:bowtie2 method, and HostAlign split to HostAlignBowtie2 and HostAlignHisat2
- add prinseq=0.20.4 for LowComplexityFilter
- add HsACRemoval
- add argument '--algorithm', PathogensAlign(s) now use 'bwa-backtrack' as default
- add SplitDisplay, ProcessEva, AioCollection

### Changed
- databases version updated

## [0.1.1] - 2020-04-01
### Added
- databases tree revision
- databases version control

### Changed
- awsFastp data processing logic changed

## [0.1.0] - 2020-03-30
### Added
- basic development completed, ready for awsbatch

## [0.0.1] - 2019-12-09
### Added
- the project is initialized

[Unreleased]: http://git.sagene.com.cn/sagene-plugins/rpdseq-reborn/compare/0.5.3...HEAD
[0.5.3]: http://git.sagene.com.cn/sagene-plugins/rpdseq-reborn/tags/0.5.3
[0.5.2]: http://git.sagene.com.cn/sagene-plugins/rpdseq-reborn/tags/0.5.2
[0.5.1]: http://git.sagene.com.cn/sagene-plugins/rpdseq-reborn/tags/0.5.1
[0.5.0]: http://git.sagene.com.cn/sagene-plugins/rpdseq-reborn/tags/0.5.0
[0.4.2]: http://git.sagene.com.cn/sagene-plugins/rpdseq-reborn/tags/0.4.2
[0.4.1]: http://git.sagene.com.cn/sagene-plugins/rpdseq-reborn/tags/0.4.1
[0.4.0]: http://git.sagene.com.cn/sagene-plugins/rpdseq-reborn/tags/0.4.0
[0.3.0]: http://git.sagene.com.cn/sagene-plugins/rpdseq-reborn/tags/0.3.0
[0.2.0]: http://git.sagene.com.cn/sagene-plugins/rpdseq-reborn/tags/0.2.0
[0.1.1]: http://git.sagene.com.cn/sagene-plugins/rpdseq-reborn/tags/0.1.1
[0.1.0]: http://git.sagene.com.cn/sagene-plugins/rpdseq-reborn/tags/0.1.0
[0.0.1]: http://git.sagene.com.cn/sagene-plugins/rpdseq-reborn/tags/0.0.1

<!--
   -[0.0.2]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.0.1...v0.0.2
   -->
