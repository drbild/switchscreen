# switchscreen

`switchscreen` is a lightweight Linux daemon that switches the input
source on a ddc-enabled monitor when the shortcut `RightAlt+F16` is
pressed.

This repository includes the source code, a `systemd` service unit for
managing the daemon, and an RPM spec file for packaging. The project
is compatible with OpenSUSE for RPM-based distributions.

## Features

- Works globally (including in lockscreens and consoles) by monitoring
  keyboard inputs directly using `libinput`.
- Executes `ddcutil` to switch the monitor input source when
  `RightAlt+F16` is pressed.
- Includes a `systemd` service for easy management.
- Supports building and installing the project locally or as an RPM
  package.

## Installation

### Prerequisites

- `libinput` (for monitoring keyboard inputs)
- `ddcutil` (for switching monitor inputs)
- `systemd` (to manage the daemon as a service)
- `make` (for building and installation)

### Building and Installing Locally

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/switchscreen.git
   cd switchscreen

1. Build the project:
   ```bash
   make all
   ```

1. Install the program and service files:
   ```bash
   sudo make install
   ```

1. Enable and start the service
   ```bash
   sudo systemctl enable switchscreen.service
   sudo systemctl start switchscreen.service
   ```

### RPM Packaging (OpenSUSE)

1. Build the RPM package:
   ```bash
   make rpm
   ```

1. Install the generated RPM package:
   ```bash
   sudo make install_rpm
   ```

1. Enable and start the service
   ```bash
   sudo systemctl enable switchscreen.service
   sudo systemctl start switchscreen.service
   ```

## Usage

After installing and starting the service, the daemon will monitor
keyboard input. Press RightAlt+F16 to switch the input source on your
monitor.

To configure which input source is switched to, customize the
`switch_screen_command` string in the `switchscreen.c` source
file. The default `ddcutil setvcp 60 0x1b` switches to input `0x1b`,
which is usually a USB-C display input.

To change the keyboard shortcut, customize the key tracking in the
`process_events` function in the `switchscreen.c` source file.

## Contributing

Please submit bugs, questions, suggestions, or (ideally) contributions
as issues and pull requests on GitHub.

### Maintainers
**David R. Bild**
+ [https://www.davidbild.org](https://www.davidbild.org)
+ [https://github.com/drbild](https://github.com/drbild)

## License
Copyright 2024 David R. Bild

Licensed under the Apache License, Version 2.0 (the "License"); you may not
use this work except in compliance with the License. You may obtain a copy of
the License from the LICENSE.txt file or at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations under
the License.
