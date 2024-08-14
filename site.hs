--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll
import           Text.Pandoc.Highlighting (Style, tango, styleToCss)
import           Text.Pandoc.Options      (ReaderOptions (..), WriterOptions (..))

--------------------------------------------------------------------------------
config :: Configuration
config = defaultConfiguration
  { destinationDirectory = "docs"
  }

main :: IO ()
main = hakyllWith config $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "posts/*.tex" $ do
        route $ setExtension "html"
        compile $ pandocCompiler'
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    match "posts/*.markdown" $ do
        route $ setExtension "html"
        compile $ pandocCompiler'
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    siteCtx

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler

    create ["css/syntax.css"] $ do
        route idRoute
        compile $ do
            makeItem $ styleToCss pandocCodeStyle

--------------------------------------------------------------------------------
siteCtx :: Context String
siteCtx =
    constField "sitename" "油菜持笔" `mappend`
    constField "indexurl" (toUrl $ "index.html") `mappend`
    constField "githuburl" "https://github.com/omegacoleman" `mappend`
    defaultContext

--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%Y/%m/%d" `mappend`
    siteCtx


--------------------------------------------------------------------------------

pandocCodeStyle :: Style
pandocCodeStyle = tango
pandocCompiler' :: Compiler (Item String)
pandocCompiler' =
  pandocCompilerWith
    defaultHakyllReaderOptions
    defaultHakyllWriterOptions
      { writerHighlightStyle   = Just pandocCodeStyle
      }

