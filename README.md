# Absence of Quasi-Majorana False Positives in Full-Shell Hybrid Nanowires

[![DOI: 10.1103/w9tp-3bbq](assets/aps-prl-badge.svg)](https://doi.org/10.1103/w9tp-3bbq)
[![Julia v1.12+](https://img.shields.io/badge/Julia-v1.12+-blue.svg)](https://julialang.org/)
[![Quantica badge](https://raw.githubusercontent.com/pablosanjose/Quantica.jl/master/docs/src/assets/badge.svg)](https://github.com/pablosanjose/Quantica.jl)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE.md)

This repository contains the code used to perform numerical calculations and generate all figures for the publication ["Absence of Quasi-Majorana False Positives in Full-Shell Hybrid Nanowires"](https://doi.org/10.1103/w9tp-3bbq).

## Abstract

Tunneling spectroscopy cannot be used as an unambiguous detection tool for Majorana zero modes (MZMs) in conventional partial-shell nanowires. The presence of smooth confinement at the end of the hybrid wire (among other sources of disorder) can create exponentially pinned zero-energy states, called quasi-MZMs, that mimic all local signatures of MZMs but lack topological protection. We find that this ambiguity in MZM detection does not occur in full-shell hybrid nanowires, an alternative nanowire design where a superconducting shell fully surrounds the semiconductor core. Acting as a synthetic vortex, a full-shell hybrid nanowire hosts Caroli-de Gennes-Matricon state analogs. In the presence of smooth confinement, these states create a topologically trivial skin at the wire's end that prevents the local probe from detecting quasi-MZMs. In this way, the same  mechanism that creates MZM impostors makes them invisible in tunneling spectroscopy, avoiding false positives produced by smooth disorder.

## About

### Prerequisites

- Julia v1.12 or higher
- Recommended: 8+ CPU cores for local parallel calculations
- For cluster execution: `make`, `ssh`, `rsync`, and `yq`

### Installation

1. Clone this repository:

   ```bash
   git clone https://github.com/CarlosP24/SP72_AbsenceQM.git
   cd SP72_AbsenceQM
   ```

2. Install dependencies:

   ```bash
   julia --project=. -e "using Pkg; Pkg.instantiate()"
   ```

### Running Calculations

#### Local Execution

For local runs with Julia parallel workers:

```bash
julia bin/launch_local.jl base_fs_mualpha
```

The calculation key is built from a system name and a suffix indicating the observable to compute.

Available system families include:

- `base_fs`, `base_fs_zoom`, `base_fs_alphazoom`, `base_fs_Zs`, `base_fs_hex`
- `base_fs_szoom`, `base_fs_szoom_weak`, `base_fs_szoom_strong`, `base_fs_sszoom`
- `base_partial`, `base_partial_szoom`, `base_partial_szoom_weak`, `base_partial_szoom_strong`

Available calculation suffixes include:

- `_mualpha`: phase diagram as a function of chemical potential and spin-orbit coupling
- `_mualphaZ`: phase diagram as a function of chemical potential, spin-orbit coupling, and angular momentum sector
- `_muflux`: phase diagram as a function of chemical potential and flux
- `_muB`: phase diagram as a function of chemical potential and Zeeman field
- `_flux`: phase diagram as a function of flux
- `_dos`: density of states
- `_doschi`: density of states versus confinement length
- `_ldos`: local density of states
- `_wfs`: low-energy wavefunctions

Examples:

```bash
julia bin/launch_local.jl base_partial_muB
julia bin/launch_local.jl base_fs_zoom_muflux
julia bin/launch_local.jl base_fs_szoom_ldos
```

#### HPC Cluster Execution

For large parameter sweeps on a SLURM cluster, use the provided deployment workflow:

```bash
make CLUSTER=esbirro ARG=base_fs_mualpha run
```

Supported cluster profiles are defined in `config/clusters.yaml` and currently include `esbirro`, `atto`, `cesga`, and `drago`.

Useful targets:

```bash
make CLUSTER=esbirro deploy
make CLUSTER=esbirro ARG=base_fs_zoom_muflux run
make CLUSTER=esbirro sync
```

### Generating Figures

Run the code in `plots/plots.jl` to generate all figures from the precomputed data in `data/`. This script will produce PDF figures in the `plots/figures/` directory.


## Repository Structure

```text
├── src/                    # Main source code
│   ├── main.jl             # Entry point for numerical calculations
│   ├── builders/           # Geometry and Hamiltonian builders
│   ├── calculations/       # DOS, LDOS, conductance, phase-diagram, and wavefunction routines
│   ├── models/             # Full-shell and partial-shell parameter sets
│   ├── operators/          # Green's functions and Pfaffian utilities
│   └── parallelizers/      # Parallel execution helpers
├── plots/                  # Figure generation environment and scripts
│   ├── plots.jl            # Runs all figure scripts
│   ├── figure_wyG.jl       # Main comparison figure
│   ├── figure_wyS.jl       # Smooth-confinement LDOS figures
│   ├── figure_skin.jl      # Trivial-skin schematic and phase-diagram figure
│   ├── figure_conductance.jl # Conductance figure
│   ├── figure_temperature.jl # Temperature-dependence figure
│   ├── plotters/           # Plotting utilities
│   ├── sketches/           # Device schematic source images
│   ├── tests/              # Plotting sanity-check scripts
│   └── figures/            # Generated PDF figures
├── bin/                    # Local and cluster launch scripts
├── config/                 # Cluster configuration and job prologue/epilogue scripts
├── data/                   # Precomputed numerical results (published) in JLD2 format
└── README.md
```

## Core Dependencies

- [Quantica.jl](https://github.com/pablosanjose/Quantica.jl): Quantum tight-binding calculations
- [FullShell.jl](https://github.com/CarlosP24/FullShell.jl): Full-shell hybrid nanowire Hamiltonians


## Citation

If you use this code in your research, please cite the associated publication:

```bibtex
@article{w9tp-3bbq,
  title = {Absence of quasi-Majorana false positives in full-shell hybrid nanowires},
  author = {Payá, Carlos and Robles, César and San-Jose, Pablo and Prada, Elsa},
  journal = {Phys. Rev. Lett.},
  pages = {},
  year = {2026},
  month = {Aug},
  publisher = {American Physical Society},
  doi = {10.1103/w9tp-3bbq},
  url = {https://link.aps.org/doi/10.1103/w9tp-3bbq}
}
```

## License

This project is licensed under the GNU General Public License v3.0. See [LICENSE.md](LICENSE.md) for details.

## Support

For questions about the code or manuscript, please open a new issue with a detailed description or contact the first author(s) listed in the manuscript.


## Acknowledgments
This research was supported by Grants PID2021-125343NB-I00, PRE2022-101362, PID2023-150224NB-I00 and CEX2024-001445-S, funded by MICIU/AEI/10.13039/501100011033, "ERDF A way of making Europe" and "ESF+".