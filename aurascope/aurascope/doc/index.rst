.. zephyr:board:: aurascope

Overview
********

Aurascope is a custom board built around the nRF5340 SoC. It reuses the
software/application structure of the nRF5340 Audio application support
(:zephyr:board:`nrf5340_audio_dk`), but its GPIO pinout matches the
nRF5340 DK (:zephyr:board:`nrf5340dk`) rather than the Audio DK, since the
physical hardware is an nRF5340 DK.

Zephyr uses the ``aurascope/nrf5340`` board configuration for building
for Aurascope.

Hardware
********

Aurascope is built around the nRF5340 SoC, which has the following characteristics:

* A full-featured Arm Cortex-M33F core with DSP instructions,
  FPU, and Armv8-M Security Extension, running at up to 128 MHz,
  referred to as the **application core**.
* A secondary Arm Cortex-M33 core, with a reduced feature set,
  running at a fixed 64 MHz, referred to as the **network core**.

The ``aurascope/nrf5340/cpuapp`` build target provides support for the application
core on the nRF5340 SoC. The ``aurascope/nrf5340/cpunet`` build target provides
support for the network core on the nRF5340 SoC.

Supported Features
==================

.. zephyr:board-supported-hw::

See :zephyr:board:`nrf5340dk` for a complete list of the underlying board hardware features.


Programming and Debugging
*************************

.. zephyr:board-supported-runners::

Flashing
========

Follow the instructions in the :ref:`nordic_segger` page to install
and configure all the necessary software. Further information can be
found in :ref:`nordic_segger_flashing`. Then you can build and flash
applications as usual (:ref:`build_an_application` and
:ref:`application_run` for more details).

.. warning::

   The nRF5340 has a flash read-back protection feature. When flash read-back
   protection is active, you will need to recover the chip before reflashing.
   If you are flashing with :ref:`west <west-build-flash-debug>`, run
   this command for more details on the related ``--recover`` option:

   .. code-block:: console

      west flash -H -r nrfutil --skip-rebuild

Debugging
=========

Refer to the :ref:`nordic_segger` page to learn about debugging Nordic
boards with a Segger IC.
