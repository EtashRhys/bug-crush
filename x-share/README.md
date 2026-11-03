# X player-card share page

Live at https://ucii.sportgen-ai.com/bug-crush/play/ (served from
/var/www/bug-crush-x-share/ on the production box, nginx location
/bug-crush/play/). The page carries twitter:card=player tags pointing
at the game itself, so an X post linking here can render a play button
and run Bug Crush inside the post on x.com (the X phone app may open
it in its own browser instead). Card image is the static splash logo
fitted to a 960x960 square. To update the live page, copy these files
to /var/www/bug-crush-x-share/ — no nginx reload needed for content.
