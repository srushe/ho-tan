# Ho-Tan - A Ruby Micropub Endpoint

Ho-Tan is a [Micropub](http://micropub.rocks/) endpoint. It is written in Ruby, as a [Sinatra](http://sinatrarb.com/) application, and supports IndieAuth authorisation, Micropub create, update, delete, and undelete commands, as well as multiple [destinations](https://indieweb.org/destination).

Ho-Tan stores all posts as JSON files, and requires no database to run. It was initially inspired by Barry Frost's [Transformative](https://github.com/barryf/transformative), but informed by my desire to separate the storage of the data from the display on a website. Ho-Tan lets me deal with posts directly in files, while allowing me to change how I process them on the back-end for display.

## What has happened to the project?

TLDR: Project (`ho-tan`) is now [hosted on Sourcehut](https://code.deeden.co.uk/ho-tan) due to GitHub's continued collaboration with ICE (U.S. Immigration and Customs Enforcement).

Hello :wave:, nice to see you! If you're here you're presumably looking for the project (`ho-tan`) that used to be here. The project still exists, it has just moved elsewhere. Let me tell you both why, and where you can find the project now.

Given GitHub's [ongoing policy of collaborating with ICE](https://thenextweb.com/politics/2019/10/09/github-microsoft-trump-ice-contract/) I don't feel comfortable supporting the platform ([as](https://deeden.co.uk/notes/2019/10/24/085956/) [I've](https://deeden.co.uk/notes/2019/11/15/094544/) [mentioned](https://deeden.co.uk/notes/2019/11/20/160118/) [elsewhere](https://deeden.co.uk/notes/2020/04/14/165427/)), so I've gradually moved all of my repositories (both private and public) elsewhere.

I've hoped that GitHub would cancel their policy ([as do many of the staff](https://www.washingtonpost.com/context/letter-from-github-employees-to-ceo-about-the-company-s-ice-contract/fb280de9-2bc3-40d5-b1a5-e3b954bf0d25/), including good people I know), but nothing has happened, so I've moved. You can find the [project at Sourcehut](https://code.deeden.co.uk/ho-tan), as well as [issue tracking](https://code.deeden.co.uk/ho-tan/issues). [Patches](https://code.deeden.co.uk/ho-tan/patches) will also still be gratefully received.