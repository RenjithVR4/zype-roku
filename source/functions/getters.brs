'getters query the api directly

Function get_search_results(query As String) as object
  url = m.api.endpoint + "/videos/?api_key=" + m.api.key + "&per_page=" + m.config.per_page + "&q=" + HttpEncode(query) + "&type=zype"
  search_results = get_video_feed(url, true)
  return search_results
End Function

Function get_featured_playlist() as object
  validation = valid_featured_playlist()

  if validation = "true"
    url = m.api.endpoint + "/playlists/" + m.config.featured_playlist_id + "/videos/?api_key=" + m.api.key + "&per_page=" + m.config.per_page
    episodes = get_video_feed(url, false)
    if(episodes.count() > 0)
      featured = {name: get_playlist_name(m.config.featured_playlist_id), episodes: episodes}
    else
      url = m.api.endpoint + "/videos/?api_key=" + m.api.key + "&per_page=10&type=zype"
      featured = {name: "New Releases", episodes: get_video_feed(url, false)}
    end if
  else
    url = m.api.endpoint + "/videos/?api_key=" + m.api.key + "&per_page=10&type=zype"
    featured = {name: "New Releases", episodes: get_video_feed(url, false)}
  endif

  return featured
End Function

Function get_playlist_name(playlist_id As String) as string
  name = ""
  url = m.api.endpoint + "/playlists/" + playlist_id + "?api_key=" + m.api.key + "&per_page=" + m.config.per_page
  res = call_api(url)
  if res.DoesExist("title")
    name = res.title
  endif
  return name
End Function

Function get_stream_url(id As String) as Object
  stream_url = {}
  url = m.api.player_endpoint + "/embed/" + id + "/?api_key=" + m.api.key
  res = call_api(url)
  if(res.DoesExist("body"))
    if(res.body.DoesExist("outputs"))
      for each output in res.body.outputs
        if(output.name = "hls")
          stream_url = output.url
          return {url: stream_url}
        end if
      end for
    endif
  endif
  return stream_url
End Function

Function get_category_playlist(category_name as string, category_value as string, category_id as string) as object
  url = m.api.endpoint + "/videos?api_key=" + m.api.key + "&category%5B" + HttpEncode(category_name) + "%5D=" + HttpEncode(category_value) + "&type=zype&per_page=" + m.config.per_page
  print url
  episodes = get_video_feed(url, false)
  if(episodes.count() > 0)
    if(m.config.prepend_category_name = true)
      playlist = {name: category_name + " " + category_value, episodes: episodes}
    else
      playlist = {name: category_value, episodes: episodes}
    endif
  endif
  return playlist
End Function

Function get_category_info(category_id As String) as Object
  request = CreateObject("roUrlTransfer")
  port = CreateObject("roMessagePort")
  request.SetPort(port)

  request.SetCertificatesFile("common:/certs/ca-bundle.crt")
  request.AddHeader("X-Roku-Reserved-Dev-Id", "")
  request.InitClientCertificates()

  url = m.api.endpoint + "/categories/" + category_id + "/?api_key=" + m.api.key
  request.SetUrl(url)
  category_info = {name: "", values: CreateObject("roArray", 1, true)}

  if(request.AsyncGetToString())
    while(true)
      msg = wait(0, port)
      if(type(msg) = "roUrlEvent")
        code = msg.GetResponseCode()
        if(code = 200)
          res = ParseJSON(msg.GetString())
          res = res.response
          category_info.name = res.title
          category_info.values = res.values
          return category_info
        endif
      else if(event = invalid)
        request.AsyncCancel()
      endif
    end while
  endif

  return invalid
End Function

'this should be turned into a parser
Function get_video_feed(url As String, short As Boolean) as object
  episodes = CreateObject("roArray", 1, true)
  res = call_api(url)
  for each item in res
    thumbnail = parse_thumbnail(item)
    rating = parse_rating(item)
    episode = {
      ID: item._id,
      ContentType: "episode",
      StreamFormat: "hls",
      Title: item.title,
      SDPosterUrl: thumbnail,
      HDPosterUrl: thumbnail,
      Length: item.duration,
      'ReleaseDate: ,
      Rating: rating,
      Description: item.description,
      SwitchingStrategy: m.config.switching_strategy
    }

    top_validation = valid_top_zobject()
    bottom_validation = valid_bottom_zobject()

    if top_validation = "true"
      episode.Actors = parse_zobjects(item, m.config.top_description_zobject)
    endif

    if bottom_validation = "true"
      episode.Categories = parse_zobjects(item, m.config.bottom_description_zobject)
    endif

    if (short = true)
      episode.ShortDescriptionLine1 = item.title
      episode.ShortDescriptionLine2 = rating
    endif
    episodes.push(episode)
  end for
  return episodes
End Function

Function HttpEncode(str As String) As String
    o = CreateObject("roUrlTransfer")
    return o.Escape(str)
End Function
