# **Design Notes**  
Author: Colin Boulé / Adaptation by ChatGPT  

## **Table of Contents**  
1. Project Introduction  
2. System Architecture  
3. Planning and Milestones  
4. Implementation Details  
5. Hardware Acceleration Analysis  
6. Deliverables  

---

## **1. Project Introduction**  

**Objective:**  
The goal of this project is to design and implement, in VHDL, a multi-effect guitar pedal that demonstrates the principles of hardware acceleration. The system processes audio entirely in hardware, without using Qsys, Nios II, or any embedded processor, enabling real-time processing with minimal latency.  

**Key Features:**  
- **Fully Hardware-Based**: No embedded processor; all processing is done in custom VHDL modules.  
- **Modular Architecture**: Each audio effect is encapsulated in its own VHDL module, promoting reusability and scalability.  
- **Real-Time Processing**: Audio is processed with imperceptible latency, suitable for live performance.  
- **Dynamic Parameterization (planned)**: Future versions may support configurable effect parameters. The architecture already anticipates this feature, but it is not implemented in the current version.  

**References and Inspiration:**  
The project draws inspiration from publicly available works — notably those by Andoni Arruti and Jose Angel Gumiel. No source code was copied directly. Our implementation is original, though certain modules may share logical or structural similarities due to the nature of audio processing algorithms.  

---

## **2. System Architecture**  

### **Overview**  
The system receives a guitar input signal, routes it through one or more effect modules, and outputs the processed signal through the audio codec. The architecture is designed to be **flexible**, making it easy to add or remove effects with minimal top-level modifications.  

**Main Components:**  
1. **Audio Input Module** – Interfaces with the WM8731 codec, receiving the guitar signal and converting it into a digital format suitable for processing.  
2. **Audio Output Module** – Interfaces with the codec to send the processed signal to speakers, headphones, or an amplifier.  
3. **Effect Modules** – Each effect is implemented as an independent hardware block, featuring:  
   - Audio input and output  
   - Enable/disable signal  
   - Configurable parameters (e.g., gain, threshold, modulation rate)  
4. **Effect Selector Multiplexer** – Routes the output of the selected effect to the final output. If no effect is enabled, the system defaults to **pass-through mode** (direct connection input → output).  

### **Implemented and Planned Effects**  
Each effect module follows a standardized interface for easier integration.  

**Current and planned effects:**  
- **Pass-Through** – Directly routes input to output (baseline reference).  
- **Overdrive** – Applies soft clipping for a warm harmonic distortion.  
- **Distortion** – Applies hard clipping for a more aggressive tone.  
- **Tremolo** – Periodic amplitude modulation.  
- **Fuzz** – Extreme clipping for a pronounced vintage-style distortion.  
- **Bitcrusher** – Reduces bit depth and/or sampling rate for a lo-fi digital effect.  

---

## **3. Planning and Milestones**  

**Deliverables:**  
- Complete Quartus Prime project files  
- Video demonstration of implemented effects  
- This design document  
- Full VHDL source code  

**Milestones:**  
1. Implement codec interface module.  
2. Achieve functional pass-through with the codec.  
3. Implement a simple fixed-gain amplifier.  
4. Develop a first basic audio effect (e.g., distortion).  
5. Implement a more complex effect (e.g., tremolo).  
6. Integrate all possible effects within time and hardware constraints.  

---

## **4. Implementation Details**  

**Development Environment:**  
- **FPGA Board**: Terasic DE1-SoC  
- **Audio Codec**: WM8731 (I²S interface)  
- **Language**: VHDL  
- **Toolchain**: Intel Quartus Prime Standard Edition  
- **Clock Frequency**: 50 MHz  

**Design Considerations:**  
- **Minimal Latency**: Effects must process audio in real time without perceptible delay.  
- **Parameter Control**: Not implemented in this version but could be added later via FPGA inputs (switches, buttons, potentiometers).  
- **Scalability**: Adding an effect requires only a new module and a connection to the multiplexer.  
- **Resource Usage**: Modules optimized for minimal logic use while maintaining audio quality.  
- **Active Effect Indication**: The six 7-segment displays show an abbreviated name of the currently selected effect.  

---

## **5. Hardware Acceleration Analysis**  

Unlike software effects running on general-purpose processors, this project uses dedicated hardware modules for each effect. This approach provides several key advantages:  

### 5.1. Parallel Processing of Modules  
Each effect is implemented in its own hardware module and can process the signal simultaneously, even when disabled.  
On a CPU, all steps (counter increment, comparison, gain calculation, multiplication) are executed **sequentially**, consuming many more cycles per sample.  

### 5.2. Deterministic Latency  
The FPGA ensures constant per-sample latency, unaffected by an OS or scheduler.  
On a CPU, latency varies depending on instruction sequencing and branch prediction, making it less predictable.  

### 5.3. High Throughput / Native Frequency  
Running at the FPGA’s native frequency allows nearly instantaneous processing per sample.  
On a CPU, processing a single tremolo sample can take **10–55 cycles**, depending on the waveform, limiting the number of real-time effects.  

### 5.4. CPU Resource Savings  
By offloading intensive signal processing to FPGA modules, CPU resources are freed for other tasks (communication, I/O, user interface).  
The file `tremolo_comparaison.c` illustrates how many CPU cycles a single tremolo effect would require, highlighting the efficiency of hardware acceleration.  

### 5.5. Modularity and Effect Chaining  
FPGA architecture makes it easy to add new effects in parallel without increasing per-sample processing time.  
Multiple effects can also be chained: on FPGA, the **added latency is about 1 cycle per effect** thanks to pipelining and parallelization.  
On CPU, each additional effect executes **sequentially**, directly increasing processing time.  



This approach highlights the core principle of hardware acceleration: **offloading computationally intensive tasks from the CPU to dedicated circuits**, improving both performance and predictability, while reducing latency for real-time audio effects.  
For more details on CPU simulation and cycle analysis, see `tremolo_comparaison.c`.  

---

## **6. Deliverables**  

### **Quartus Project**  
- **Top Level**: `SadModz.vhdl`  
- **Source Folder**: `sources`  
- **Effect Modules:**  
  - `Overdrive.vhdl`  
  - `Distortion.vhdl`  
  - `Tremolo.vhdl`  
  - `Fuzz.vhdl`  
  - `Bit_crusher.vhdl`  
- **Codec Modules:**  
  - `WM8731_config.vhdl`  
  - `audio_in.vhdl`  
  - `audio_out.vhdl`  

