---
title: Operating systems
weight: 2
---

The operating system (OS) dictates how system admins and users interact with the computational hardware of the lab.
They come with different purposes, design decisions, and ecosystems for high-performance computing.
Since November of 2017, [100% of supercomputers use linux](https://www.top500.org/statistics/details/osfam/1/) and we are no different.
[RedHat Enterprise Linux](https://www.redhat.com/en) (RHEL) is by far the most popular operating system, followed by [Ubuntu](https://ubuntu.com/) and Cray.

| Operating System | Percentage (%) [^1] |
| :--------------: | :------------: |
| RHEL | 20.0 |
| Ubuntu | 11.8 |
| Cray | 9.8 |
| CentOS [^2] | 8.2 |
| Rocky | 5.8 |

## Cost

**tl;dr**: RHEL is not free for any scale.
Ubuntu is free with an optional paid subscription for additional support (i.e., no feature locks).

Cost is always the first factor I consider when choosing an OS.
RHEL is free for [up to 16 nodes](https://developers.redhat.com/articles/faqs-no-cost-red-hat-enterprise-linux#general) through its [RedHat Developer program](https://developers.redhat.com/products/rhel/overview).
Its use is limited to development, testing, and small production uses spanning personal servers, home labs, and small open-source communities.
In other words, not small organizations or teams.

Ubuntu, both server and desktop, are completely free with the optional paid subscription of [Ubuntu Pro](https://ubuntu.com/pro).
This service primarily provides additional security maintenance, dedicated support, and easier system management.

## Decision

Given that academic labs often run on tight budges, we are recommending Ubuntu.
Next, we will discuss near automated setup of our Ubuntu operating system.

[^1]: Operating system distributions for world's supercomputers are from the June 2025 [TOP500 release](https://www.top500.org/statistics/list/).
[^2]: CentOS has been replaced with [CentOS Stream](https://www.redhat.com/en/topics/linux/what-is-centos-stream) that is an upstream repository of RedHat.
