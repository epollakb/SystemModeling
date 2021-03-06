(*
    Monadic Epidemiology Compartmental Modeling Mathematica unit tests
    Copyright (C) 2020  Anton Antonov

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    Written by Anton Antonov,
    antononcube@gmail.com,
    Windermere, Florida, USA.
*)

(*
    Mathematica is (C) Copyright 1988-2020 Wolfram Research, Inc.

    Protected by copyright law and international treaties.

    Unauthorized reproduction or distribution subject to severe civil
    and criminal penalties.

    Mathematica is a registered trademark of Wolfram Research, Inc.
*)

(* :Title: EpidemiologyModels-Unit-Tests *)
(* :Context:  *)
(* :Author: Anton Antonov *)
(* :Date: 2020-04-08 *)

(* :Package Version: 0.1 *)
(* :Mathematica Version: 12.1 *)
(* :Copyright: (c) 2020 Anton Antonov *)
(* :Keywords: monad, Epidemiology model, unit test *)
(* :Discussion:

   This test files has unit tests for the functions in the package:

      https://github.com/antononcube/SystemModeling/blob/master/Projects/Coronavirus-propagation-dynamics/WL/MonadicEpidemiologyCompartmentalModeling.m

*)

BeginTestSection["MonadicEpidemiologyCompartmentalModeling-Unit-Tests.mt"];

VerificationTest[
  CompoundExpression[
    Import["https://raw.githubusercontent.com/antononcube/SystemModeling/master/Projects/Coronavirus-propagation-dynamics/WL/MonadicEpidemiologyCompartmentalModeling.m"],
    Greater[Length[SubValues[MonadicEpidemiologyCompartmentalModeling`ECMMonSimulate]], 0]
  ]
  ,
  True
  ,
  TestID -> "LoadPackage"
];


(**************************************************************)
(* Data                                                       *)
(**************************************************************)

VerificationTest[
  SeedRandom[2129];
  coords = RandomVariate[MultinormalDistribution[{10, 10}, 7 IdentityMatrix[2]], 200];
  aPopulations = Association @ Map[# -> RandomInteger[{10, 100}] &, coords];
  aInfected = 0.1 * aPopulations;
  aDead = 0.01 * aPopulations;
  MatrixQ[coords, NumberQ] && Apply[ And, AssociationQ /@ {aPopulations, aInfected, aDead} ]
  ,
  True
  ,
  TestID -> "GenerateData-1"
];


(**************************************************************)
(* SubtractByKeys                                             *)
(**************************************************************)

VerificationTest[
  Keys[SubtractByKeys[aDead, aPopulations]] == Keys[aDead]
  ,
  True
  ,
  TestID -> "SubtractByKeys-1"
];


(**************************************************************)
(* Multi-site model derivation                                *)
(**************************************************************)

VerificationTest[
  ecmHexObj =
      DoubleLongRightArrow[
        ECMMonUnit[],
        ECMMonMakePolygonGrid[Keys[aPopulations], 15, "BinningFunction" -> "HextileBins" ],
        ECMMonPlotGrid[ImageSize -> Medium, "Echo" -> False],
        ECMMonExtendByGrid[aPopulations, 0.12],
        ECMMonAssignInitialConditions[<||>, "Total Population", "Default" -> 1.2*^6]
      ];
  Sort[Keys[ecmHexObj[[2]]]] == Sort[{"grid", "singleSiteModel", "multiSiteModel"}]
  ,
  True
  ,
  TestID -> "MultiSiteModel-hexagonal-grid-creation-and-extension-1"
];


VerificationTest[
  ecmObj1 =
      DoubleLongRightArrow[
        ECMMonUnit[],
        ECMMonMakePolygonGrid[Keys[aPopulations], 15, "BinningFunction" -> Automatic ],
        ECMMonExtendByGrid[aPopulations, 0.12]
      ];

  ecmObj2 =
      DoubleLongRightArrow[
        ECMMonUnit[],
        ECMMonMakePolygonGrid[Keys[aPopulations], 15, "BinningFunction" -> "HextileBins" ],
        ECMMonExtendByGrid[aPopulations, 0.12]
      ];

  ecmObj1 == ecmObj2
  ,
  True
  ,
  TestID -> "MultiSiteModel-hexagonal-grid-creation-and-extension-2"
];


VerificationTest[
  ecmObj3 =
      DoubleLongRightArrow[
        ECMMonUnit[],
        ECMMonMakePolygonGrid[Keys[aPopulations], 15, "BinningFunction" -> "TileBins" ],
        ECMMonPlotGrid[ImageSize -> Medium, "Echo" -> False],
        ECMMonExtendByGrid[aPopulations, 0.12],
        ECMMonAssignInitialConditions[<||>, "Total Population", "Default" -> 1.2*^6]
      ];
  Sort[Keys[ecmObj3[[2]]]] == Sort[{"grid", "singleSiteModel", "multiSiteModel"}]
  ,
  True
  ,
  TestID -> "MultiSiteModel-rectangular-grid-creation-and-extension-1"
];


(**************************************************************)
(* Multi-site initial conditions                              *)
(**************************************************************)

VerificationTest[

  ecmHexObj =
      DoubleLongRightArrow[
        ecmHexObj,
        ECMMonAssignInitialConditions[ aPopulations, "Total Population", "Default" -> 0 ],
        ECMMonAssignInitialConditions[ DeriveSusceptiblePopulation[aPopulations, aInfected, aDead], "Susceptible Population", "Default" -> 0 ],
        ECMMonAssignInitialConditions[<||>, "Exposed Population", "Default" -> 0],
        ECMMonAssignInitialConditions[aInfected, "Infected Normally Symptomatic Population", "Default" -> 0],
        ECMMonAssignInitialConditions[<||>, "Infected Severely Symptomatic Population", "Default" -> 0]
      ];

  Sort[Keys[ecmHexObj[[2]]]] == Sort[{"grid", "singleSiteModel", "multiSiteModel"}]
  ,
  True
  ,
  TestID -> "MultiSiteModel-initial-conditions-1"
];

VerificationTest[

  maxPopulation = 1.2*^6;

  ecmHexObj2 =
      DoubleLongRightArrow[
        ecmHexObj,
        ECMMonAssignInitialConditions[<||>, "Total Population", "Default" -> maxPopulation ];
        ECMMonAssignInitialConditions[<||>, "Susceptible Population", "Default" -> maxPopulation ],
        ECMMonAssignInitialConditions[<||>, "Exposed Population", "Default" -> 0],
        ECMMonAssignInitialConditions[<||>, "Infected Normally Symptomatic Population", "Default" -> 0],
        ECMMonAssignInitialConditions[<||>, "Infected Severely Symptomatic Population", "Default" -> 0],
        ECMMonAssignInitialConditions[<|ISSP[1][0] -> 1, SP[1][0] -> maxPopulation - 1|>]
      ];

  con = ECMMonBind[ ecmHexObj2, ECMMonTakeContext];

  AssociationQ[con] && Sort[Keys[con]] == Sort[{"grid", "singleSiteModel", "multiSiteModel"}]
  ,
  True
  ,
  TestID -> "MultiSiteModel-initial-conditions-2"
];


(**************************************************************)
(* Multi-site simulation                                      *)
(**************************************************************)

VerificationTest[

  ecmHexObj2 =
      DoubleLongRightArrow[
        ecmHexObj,
        ECMMonSimulate[12]
      ];

  con = ECMMonBind[ecmHexObj2, ECMMonTakeContext];

  AssociationQ[con] && ( Sort[Keys[con]] == Sort[{"grid", "singleSiteModel", "multiSiteModel", "solution"}] )
  ,
  True
  ,
  TestID -> "MultiSiteModel-simulation-1"
];

VerificationTest[

  sol = ECMMonBind[ecmHexObj2, ECMMonTakeContext]["solution"];

  AssociationQ[sol] && MatchQ[sol, <|(_ -> (_InterpolatingFunction)) ..|>]
  ,
  True
  ,
  TestID -> "MultiSiteModel-simulation-solution-1"
];

VerificationTest[

  res =
      Fold[ ECMMonBind,
        ecmHexObj2,
        {
          ECMMonPlotSolutions[__ ~~ "Population", 12, "Echo" -> False],
          ECMMonTakeValue
        }];

  MatchQ[res, Legended[_Graphics, _]]
  ,
  True
  ,
  TestID -> "MultiSiteModel-simulation-plot-1"
];

VerificationTest[

  res =
      Fold[ ECMMonBind,
        ecmHexObj2,
        {
          ECMMonPlotSolutions[{"Recovered Population", "Susceptible Population"}, 12, "Echo" -> False],
          ECMMonTakeValue
        }
      ];

  MatchQ[res, Legended[_Graphics, _]]
  ,
  True
  ,
  TestID -> "MultiSiteModel-simulation-plot-2"
];

VerificationTest[
  res =
      Fold[ ECMMonBind,
        ecmHexObj2,
        {
          ECMMonPlotSolutions[All, 12, "Echo" -> False],
          ECMMonTakeValue
        }
      ];
  MatchQ[res, Legended[_Graphics, _]]
  ,
  True
  ,
  TestID -> "MultiSiteModel-simulation-plot-3"
];



EndTestSection[]
