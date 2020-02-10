{-# LANGUAGE NoImplicitPrelude #-}
-- | Provide a @`SimpleApp`@ datatype, for providing a basic @App@-like
-- environment with common functionality built in. This is intended to
-- make it easier to, e.g., use rio's logging and process code from
-- within short scripts.
--
-- @since 0.1.3.0
module RIO.Prelude.Simple
  ( SimpleApp
  , mkSimpleApp
  , runSimpleApp
  ) where

import RIO.Prelude.Reexports
import RIO.Prelude.Logger
import RIO.Prelude.Lens
import RIO.Prelude.RIO
import RIO.Process
import System.Environment (lookupEnv)

-- | A simple, non-customizable environment type for @RIO@, which
-- provides common functionality. If it's insufficient for your needs,
-- define your own, custom @App@ data type.
--
-- @since 0.1.3.0
data SimpleApp = SimpleApp
  { saLogFunc :: !LogFunc
  , saProcessContext :: !ProcessContext
  }
instance HasLogFunc SimpleApp where
  logFuncL = lens saLogFunc (\x y -> x { saLogFunc = y })
instance HasProcessContext SimpleApp where
  processContextL = lens saProcessContext (\x y -> x { saProcessContext = y })


-- | Constructor for `SimpleApp`. In case when `ProcessContext` is not supplied
-- `mkDefaultProcessContext` will be used to create it.
--
-- @since 0.1.14.0
mkSimpleApp :: MonadIO m => LogFunc -> Maybe ProcessContext -> m SimpleApp
mkSimpleApp logFunc mProcessContext = do
  processContext <- maybe mkDefaultProcessContext pure mProcessContext
  pure $ SimpleApp {saLogFunc = logFunc, saProcessContext = processContext}


-- | Run with a default configured @SimpleApp@, consisting of:
--
-- * Logging to stderr
--
-- * If the @RIO_VERBOSE@ environment variable is set, turns on
--   verbose logging
--
-- * Default process context
--
-- @since 0.1.3.0
runSimpleApp :: MonadIO m => RIO SimpleApp a -> m a
runSimpleApp m = liftIO $ do
  verbose <- isJust <$> lookupEnv "RIO_VERBOSE"
  lo <- logOptionsHandle stderr verbose
  withLogFunc lo $ \lf -> do
    simpleApp <- mkSimpleApp lf Nothing
    runRIO simpleApp m
