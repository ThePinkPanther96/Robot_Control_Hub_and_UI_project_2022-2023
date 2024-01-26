# Robot Control Hub & UI project - 2022-2023
## Introduction
During my role as an Integration Engineer at a medical robotics startup company, one of my principal goals has been to develop a transformative project with far-reaching objectives for the life cycle of the robot management console. It was a small startup company that had just started releasing the first versions of the robot they had been developing for about 7 years.

The robot was constructed with three main parts: The robot unit itself, which would have been placed directly on the patient's body where the procedure was to be performed. The drivers and controllers were in charge of controlling the robot's mechanical components. The third part was the management console from which the .NET-based application operated, which is the main focus of this article. The console was based on Windows 10 Enterprise and worked completely offline, due to regulations. The application that operated the robot was in its early stages and was missing many key components needed for complete control of the robot, such as CT scanners, new needles, and different parameters that needed to be configured for each procedure, as well as new site configuration, software, and OS updates. 

In order to complete all of these tasks, the Field Service Engineers often resorted to digging up the XML databases and manually editing them via Notepad – not a very good idea to let an unexperienced Field Service Engineer tinker with critical files that directly control the robot's behavior. Another issue was the badly configured OS itself, which went against all of Microsoft's OS imaging, deployment, and configuration best practices, due to a lack of knowledge and the hurry to get the product to the market as soon as possible.

The worst thing about all of this, besides the poor system performance and the risk of fatal mistakes resulting from manual work in the field, was the lack of proper documentation. It's important to understand that a device that is going to be approved by the FDA needs to be heavily configured and restricted to comply with regulations. In Windows, if you don't know what you're doing – if you don't know how to configure Group Policies, the Registry, system settings, source control Windows images, etc., and use the various tools that Microsoft offers to configure the system correctly – then it's only a matter of time until something bad happens. 

### These were my primary goals
Pioneering an end-to-end cloud-based full Life-cycle infrastructure for the Robot Operating system, encompassing development, deployment, updates, and maintenance, while simplifying the development, testing, and validation processes to enhance maintenance and reduce workloads on other development teams.
Restructuring the robot OS environment to reduce complexity as well as enhance technical documentation precision.
Implementing cumulative updates to enhance system maintenance and migrations with automated solutions and custom applications. Using industry-standard tools such as MDT and Advanced Installer, to eliminate the reliance on full OS images with outdated imaging tools, to facilitate seamless integration across diverse sites.
Harnessed .NET Framework and PowerShell to create a custom application precisely designed for the robot console, for managing the OS, Robot Database, user preferences, network settings, and troubleshooting.

*Unfortunately, I never got to finish my project because the company closed its doors in late 2023. However, I believe it would be a shame to let all the effort I put into creating this project go to waste. I realized that many parts of my code could be valuable for other PowerShell developers, helping them gain knowledge and learn new techniques to inspire and improve their coding abilities further*  

**Please Note** Some parts of the project might appear unusual or out of place because I had to replace numerous logos, backgrounds, and visual components due to copyright concerns, making them suitable for publication.
So, as far as you are concerned, the company name is ```X Robotics``` and the robot application name is ```X_app```

**Also Note** Some functions/code blocks are not functional or buggy. But, most of the code is usable and has been tasted. See comments in the code.

**For more information** on the project and its ideas, feel free to visit my *[LinkedIn](https://www.linkedin.com/in/gal-rozman/)* profile, where you'll find a *[PowerPoint presentation](https://www.linkedin.com/in/gal-rozman/overlay/1635539223012/single-media-viewer/?type=DOCUMENT&profileId=ACoAADb0dEgB0XA9XqaC5tDpiGjRjleHqSenoq8)* about it. You can also reach me via *email at gal8156@gmail.com*

### In this tutorial, I will provide general instructions on setting up and operating the project as originally intended. 

## Requirements
- Windows 10 Enterprise/Pro
- At least 2 users on the system (one admin)
- At least 2 drives - The second drive letter must be 'D'
- Visual Studio for building the application

## Dependencies 
- .NET Framework 4.8 or higher
- PowerShellGet 3 or higher
- AutoHotkey 1.1.36 or higher
- NuGet 3 or higher
- PowerShell 7
- Microsoft Visual C++
- Execution policy set to 'Unrestricted'

