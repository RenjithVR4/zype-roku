Library "v30/bslDefender.brs"

Function visitor_screen() as object
  canvas = CreateObject("roImageCanvas")
  port = CreateObject("roMessagePort")
  posArray = GetPositions()
  background = []
  items = []
  selectedIndex = 0

  canvas.SetMessagePort(port)
  canvasRect = canvas.GetCanvasRect()
  background.Push({
    url: "pkg:/images/sample-visitor-screen.png",
    CompositionMode: "Source"
    TargetRect: {x: 335, y: 110}
  })

  items.Push({
      url: "pkg:/images/activate.png"
      TargetRect: posArray[0]
  })
  items.Push({
      url: "pkg:/images/browse.png"
      TargetRect: posArray[1]
  })


  ring = {
      url: "pkg:/images/border.png",
      TargetRect: {x: posArray[selectedIndex].x, y: posArray[selectedIndex].y}
  }

  canvas.SetLayer(0, {Color:"#2b2b2b", CompositionMode:"Source"})
  canvas.SetLayer(1, background)
  canvas.SetLayer(2, items)
  canvas.SetLayer(3, ring)
  canvas.Show()

  while true
      event = wait(0, port)
      if (event<> invalid)
        if (event.isRemoteKeyPressed())
          index = event.GetIndex()
          print index
          if (index = 0)
            return -1
          else if (index = 2) OR (index = 3) OR (index = 4) OR (index = 5)'any arrow
            if selectedIndex = 0
              selectedIndex = 1
            else
              selectedIndex = 0
            endif
        else if (index = 6) 'OK
          if selectedIndex = 0
            refresh_pin_screen()
          else if selectedIndex = 1
            home_screen()
          end if
        endif
        ring.TargetRect = {x: posArray[selectedIndex].x, y: posArray[selectedIndex].y}
        canvas.SetLayer(2, items)
        canvas.SetLayer(3, ring)
      endif
    endif
  end while
End Function

'position of the two images
Function GetPositions() as object
  posArray = []
  posArray.Push({x: 400, y: 600}) 'position of first button
  posArray.Push({x: 800, y: 600}) 'position of second button
  return posArray
End Function