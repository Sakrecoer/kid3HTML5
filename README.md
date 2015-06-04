# kid3HTML5
To export a deployable website jukebox served with static HTML5-files by simply tagging your mp3 correctly, using kid3. http://kid3.sourceforge.net/

## Variables 

### Index File
`%{artist}` `%{title}` `%{track}` `%{album}` `%{comment}` `%{year}` `%{genre}` `%{duration}` `%{lyrics}` `%{etc....*`

`%{albumart}` (hypothetic) full filename. 

`%{filename}` filename, excluding extension

### Player File
`%{artist}` `%{title}` `%{track}` `%{album}` `%{comment}` `%{year}` `%{genre}` `%{duration}` `%{lyrics}` `%{etc....*`

`%{albumart}` (hypothetic), full filename 

`%{filename}` filename, excluding extension

`%{extension}` extension of _audio_ files

`%{previous_filename}` (hypothetic), if not first in list, full filename of previous HTML file

`%{next_filename}` (hypothetic) if not last, full filename of next HTML file.

Procedure:
- User puts audio files of the playlist in a folder.
- Tagg them correctly adds albumart, making sure everything is fine.
- Exports to HTML5.
- Kid3 create a folder in user location with %{artist}-%{album}
- Copies kid3index.css and kid3player.css to folder %{artist}-%{album}
- Kid3 creates an indexfile with a link to each track
- For each audio-file:
 - store %{filename} of audiofile, look ahead and backward in line to generate play_previous/next mechanism.
 - export first found image embeded in tags to folder %{artist}-%{album}, store its filename to %{albumart}
 - create %{filename}.html 
 - copy audio file to %{artist}-%{album} folder
 - wish me Santa: convert to complementing audio format.

# Bugcrap Mindfood
#### 2015/31/5
I still hesitate. Perhaps its easier to make kid3 spit jekyll posts to provide custom layouts?

#### 2015/31/5
At this point the render version works, tho it's missing the JSON-LD part. Assuming that kid3 can be aware of a context for the next/previous system to work, this could be a cool feature. Maybe create 3 preset styles? I will present this, and see whats possible. Crossfingers. Worstcase scenario: i have jekyll music CMS module waiting to be filled by post created with kid3.... :)

#### 2015/06/01 
gah playnext bug fixd. Thoughts: rendering a folder buildable by jekyll is the only way to provide full freedom on the layout. Because this feature gives the desire to tweak the layout..

#### 2015/06/04
All files related to the same song should have same name, but ehm, different extensions. For this reason, this particular set-up cannot have more than one picture file per song. There is a browser audio compatibility issue between mp3 and ogg in HTML5. Can we sniff for audiofile side-cars? Should the user be instructed to create a copy of the playlist in the other format afterwards? It it'salot confuzing too? 

if only one audio file with %{filename} is found:
```
 <audio>
  <source src="%{filename}.%{extension}" type="%{codec}" />
  <h1>Your browser isn't ready for so much hotness. Use the <a href="%{filename}.%{extension}">download-link</a> instead.</h1>.
 </audio>
```
if 2 audio files with the same %{filename} are found:
```
 <audio>
  <source src="%{filename}.%{extension}" type="%{codec}" />
  <source src="%{filename}.%{extension}" type="%{codec}" />
  <h1>Your browser isn't ready for so much hotness. Use the <a href="%{filename}.%{extension}">%{codec} download-link</a> or the <a href="%{filename}.%{extension}">%{codec} download-link</a> instead.</h1>.
 </audio>
```
