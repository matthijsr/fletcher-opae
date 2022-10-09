# Using `vhdmmio`

[`vhdmmio`](https://github.com/abs-tudelft/vhdmmio) generates the MMIO interfaces for the design based on YAML files.

## Default behavior

By default, fletchgen will generate a `fletchgen.mmio.yaml` file for the design and call `vhdmmio`, provided you use the `--mmio` flag and set the `--mmio-offset` argument, e.g.:

```bash
fletchgen -n Sum -r example.rb -l vhdl --mmio64 --mmio-offset 64 --axi
```

## Targeting Intel FPGAs

### Accelerator UUID
Intel requires that [an AFU features an accelerator UUID](https://www.intel.com/content/www/us/en/docs/programmable/683129/1-2-and-2-0-1/specify-the-afu-s-uuid.html), which is specified by your `afu-image:accelerator-clusters:accelerator-type-uuid` property in the `<design>.json` file.

The UUID is not derived from anything, it simply needs to be unique, so can be randomly generated (using `uuidgen`, for example).

### AFU CSR Definitions

[AFUs should implement five control status registers](https://www.intel.com/content/www/us/en/docs/programmable/683193/current/mandatory-csr-definitions.html), `DEV_FEATURE_HDR` (`DFH`), `AFU_ID_L`, `AFU_ID_H`, `DFH_RSVD0`, and `DFH_RSVD1`. (Also see [Intel's own example](https://www.intel.com/content/www/us/en/docs/programmable/683190/1-3-1/hello-afu-example-pll.html))

Fletchgen does not include these in `fletchgen.mmio.yaml`, as these are Intel-specific registers.

To specify them, we can add `behavior: constant` fields to first addresses of the generated `fletchgen.mmio.yaml`, containing their values. It would be a good idea to create a separate `<design>.mmio.yml` file and include it in version control (while still excluding any generated files).

See [`sum.mmio.yml`](https://github.com/matthijsr/fletcher-opae/blob/8c5133b77d4af6f04994df9b89ca3c2175127046/examples/sum/hw/sum.mmio.yml#L18-L41) as an example:
```yaml
  - address: 0b0---
    name: AFU_DFH
    behavior: constant
    value: 17293826967149215744 # [63:60]: 1 && [40]: 1

  - address: 0b1---
    name: AFU_ID_L
    behavior: constant
    value: 13797985263751972578 # check sum.json

  - address: 0b10---
    name: AFU_ID_H
    behavior: constant
    value: 13609688667197753651 # check sum.json
  
  - address: 0b11---
    name: DFH_RSVD0
    behavior: constant
    value: 0

  - address: 0b100---
    name: DFH_RSVD1
    behavior: constant
    value: 0
```

Their specific values can be set as follows:
* `AFU_DFH` can remain `17293826967149215744`. This simply sets `[63:60]` to be `1`, identifying the device as an AFU, and `[40]` to be `1`, identifying this as the last header.
* `AFU_ID_L` should be the *lower* 64 bits of the 128-bit UUID specified in your `<design>.json`. Simply convert it to binary, then convert those 64 bits to an unsigned integer for `vhdmmio`.
* `AFU_ID_H` then contains the *upper* 64 bits of the UUID.
* `DFH_RSVD0` and `DFH_RSVD1` are reserved, and unused. The value can be set to `0`.

Note that the chosen `name`s are irrelevant, only the `address`es matter.

After creating your custom `<design>.mmio.yml`, manually run

```bash
vhdmmio -V vhdl -P vhdl <design>.mmio.yml
```
in order to generate the proper MMIO interfaces for your AFU.