This module is a library of some enumerations for the Haskell base types.
These are used to construct enumerated generators for base types using
enumerative strategies described in EnumStrat.lhs.  Enumerations can be added
as required for other base types here.

The base types (Int, Char) are ``flat'', meaning there is no structure to their
definition and no need to provide a rank to their generation.  BaseEnum is an
unranked enumeration to represent these flat types.  Note that not all
``scalar'' types are base types, and may require ranked enumerations (e.g.
Integer, Double).


\begin{code}
module Test.GenCheck.Generator.BaseEnum
 ( makeBaseEnum
 , BaseEnum(..)
 , EnumGC(..)
 , baseCounter
 , baseSelector
 , getBase
 , getBaseUnsafe
 , enumList
 , enumBaseRange
 , enumBaseInt
 , enumBaseNat
 , enumBasePosInt
 , enumDfltInt
 , enumInteger
 , enumBaseChar
 , enumBaseBool
 , enumDfltChar
 , enumLowChar
 , enumUpperChar
 , enumDigitChar
 -- , beMemoize
 -- , beProd
-- , bsProd
 ) where

import Data.Char
import Data.List (genericLength)

import Test.GenCheck.Base.Base(Count)
import Test.GenCheck.Generator.Enumeration (Label)

\end{code}

Base types are unranked.  Base type enumerations are not memoized
because they are more likely to be accessed randomly than linearly,
and because they are generally very efficient.

\begin{code}
type BaseSelector a = Count -> a
data BaseEnum a = Base {baseCount::Count, baseSelect :: BaseSelector a }

makeBaseEnum :: Count -> BaseSelector a -> BaseEnum a
makeBaseEnum cnt sel = Base cnt sel

baseCounter  :: BaseEnum a -> Count
baseCounter = baseCount
baseSelector :: BaseEnum a -> BaseSelector a
baseSelector = baseSelect

getBase :: BaseEnum a -> Count -> Maybe a
getBase (Base c s) n | (n > 0)   = if c >= n then Just (s (n-1)) else Nothing
getBase _  _         | otherwise = Nothing

getBaseUnsafe :: BaseEnum a -> Count -> a
getBaseUnsafe  (Base _ s) n = s (n-1)

\end{code}

Any list is a base enumeration, with the index provided by list position.
Any instance of Haskell's Enum class provides a base enumeration,
with enumBaseRng providing the enumeration over an arbitrary range of values.

\begin{code}
  
enumList :: [a] -> BaseEnum a
enumList xs = makeBaseEnum (genericLength xs) (((!!) xs).fromInteger)

enumBaseRange :: (Enum a) => (a,a) -> BaseEnum a
enumBaseRange (l,u) = 
  let shift = toInteger (fromEnum l)
      cnt = ((toInteger (fromEnum u)) - shift) + 1
  in makeBaseEnum cnt (\x -> toEnum (fromInteger (x + shift - 1)))
\end{code}

If the type is also Bounded, then the enumeration can be over the entire set of
values.

An Integer enumeration can be built using an arbitrary range;
this is similar to enumBaseRange but without the typecasting.

\begin{code}
enumBaseInt, enumBaseNat, enumBasePosInt, enumDfltInt :: BaseEnum Int
enumBaseInt    = enumBaseRange (minBound::Int, maxBound::Int)
enumBaseNat    = enumBaseRange (0::Int, maxBound::Int)
enumBasePosInt = enumBaseRange (1::Int, maxBound::Int)
enumDfltInt    = enumBaseRange (-100::Int, 100::Int)

enumInteger :: (Integer,Integer) -> BaseEnum Integer
enumInteger (l,u) = makeBaseEnum (u - l + (1::Integer)) s
  where s x = x + l - (1::Integer)

enumBaseBool :: BaseEnum Bool
enumBaseBool = makeBaseEnum 2 (\k -> k==1)

enumBaseChar, enumDfltChar, enumLowChar, enumDigitChar, enumUpperChar :: BaseEnum Char
enumBaseChar   = enumBaseRange (minBound::Char, maxBound::Char)
enumDfltChar   = makeBaseEnum 95 (\k -> chr ((32 +) (fromInteger k))) -- ' ' to '~'
enumLowChar    = makeBaseEnum 26 (\k -> chr ((97 +) (fromInteger k)))
enumDigitChar  = makeBaseEnum 10 (\k -> chr ((48 +) (fromInteger k)))
enumUpperChar  = makeBaseEnum 26 (\k -> chr ((65 +) (fromInteger k)))

\end{code}

GenCheck supplies an alternative interface to the Haskell Enum class, that
provides a selector function for the type and a default range of values of that
type.  Any Enum instance has an automatic EnumGC instance, but this is not
provided because the type variable is ambiguous, so must be explicitly
provided.

A default instance of EnumGC for Integer is provided by 
giving arbitrary bounds of double the Int boundaries.

\begin{code}
class EnumGC a where
  base     :: BaseEnum a

instance EnumGC Label where
  base = let lbls = ([minBound..maxBound]:: [Label]) in enumList lbls

instance EnumGC Int where
  base = let c = (toInteger (maxBound::Int)) - (toInteger (minBound::Int)) + (1 :: Integer)
         in Base c (\i -> (fromInteger (i - (toInteger (maxBound::Int)))))

instance EnumGC Integer where
  base = enumInteger ( (2::Integer) * (toInteger (minBound::Int))
                     , (2::Integer) * (toInteger (maxBound::Int)) )

instance EnumGC Char where
  base = let c = ((toInteger.fromEnum) (maxBound::Char)) 
                 - ((toInteger.fromEnum) (minBound::Char)) + (1 :: Integer)
         in Base c (toEnum.fromInteger)
\end{code}


