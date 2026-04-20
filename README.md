# mini-oran-du-ru-lab
<img width="1087" height="476" alt="image" src="https://github.com/user-attachments/assets/1e281b49-c222-43c8-8dad-baa150925ba1" />

A compact “DU/RU-like” lab project demonstrating:
- OFDM baseband DSP primitives (FFT-centric)
- fixed-point, ASIC-portable RTL blocks (clear bit-growth / rounding / saturation)
- streaming dataflow with backpressure-safe interfaces
- measurable KPIs (latency / throughput / saturation / quality metrics)

## Why this project
To showcase end-to-end HW DSP work with an ASIC mindset: clean RTL, verification, and measurable results.

## Architecture (high level)
**IQ In → (CP remove) → FFT → (optional EQ) → KPI → IQ/KPI Out**

Block diagram: `docs/block_diagram.png`

## Current status
- [x] Fixed-point primitives: saturated add/sub  
- [x] Q1.15 multiply (with saturation)  
- [x] Complex multiply pipeline + valid alignment  
- [ ] AXI-stream wrappers (drop-free under backpressure)  
- [ ] FFT butterfly + twiddles  
- [ ] FFT core (N=256/512)  
- [ ] CP remove  
- [ ] KPI block (power / counters / quality metric)  

## Verification
- Unit tests for primitives and complex multiply
- Random + corner-case vectors
- Backpressure stress tests for streaming wrappers

## Repo structure
- `rtl/`     — synthesizable RTL
- `tb/`      — testbenches
- `docs/`    — diagrams, fixed-point spec, latency tables
- `logs/`    — daily progress logs
- `results/` — waveform screenshots / plots / ILA captures

## Daily updates
See `logs/YYYY-MM-DD.md`

## License
- MIT
