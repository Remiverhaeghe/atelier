import '../l10n/gen/app_localizations.dart';
import '../logic/ready_projects.dart';

String readyProjectName(AppLocalizations pText, ReadyProject pProject) => switch (pProject) {
  ReadyProject.wallShelf => pText.readyWallShelf,
  ReadyProject.fixedFrame => pText.readyFixedFrame,
  ReadyProject.mezzanine => pText.readyMezzanine,
  ReadyProject.roofReveal => pText.readyRoofReveal,
};

String readyProjectIntro(AppLocalizations pText, ReadyProject pProject) => switch (pProject) {
  ReadyProject.wallShelf => pText.readyWallShelfIntro,
  ReadyProject.fixedFrame => pText.readyFixedFrameIntro,
  ReadyProject.mezzanine => pText.readyMezzanineIntro,
  ReadyProject.roofReveal => pText.readyRoofRevealIntro,
};

String partName(AppLocalizations pText, PartKind pKind) => switch (pKind) {
  PartKind.shelfBoard => pText.readyPartShelfBoard,
  PartKind.cleat => pText.readyPartCleat,
  PartKind.stile => pText.readyPartStile,
  PartKind.rail => pText.readyPartRail,
  PartKind.glazingBead => pText.readyPartGlazingBead,
  PartKind.joist => pText.readyPartJoist,
  PartKind.ledger => pText.readyPartLedger,
  PartKind.frontBeam => pText.readyPartFrontBeam,
  PartKind.post => pText.readyPartPost,
  PartKind.floorPanel => pText.readyPartFloorPanel,
  PartKind.sideBoard => pText.readyPartSideBoard,
  PartKind.headBoard => pText.readyPartHeadBoard,
  PartKind.sillBoard => pText.readyPartSillBoard,
  PartKind.batten => pText.readyPartBatten,
};

String buyName(AppLocalizations pText, BuyKind pKind) => switch (pKind) {
  BuyKind.woodScrews => pText.readyBuyWoodScrews,
  BuyKind.wallScrews => pText.readyBuyWallScrews,
  BuyKind.wallPlugs => pText.readyBuyWallPlugs,
  BuyKind.woodGlue => pText.readyBuyWoodGlue,
  BuyKind.sandpaper => pText.readyBuySandpaper,
  BuyKind.varnish => pText.readyBuyVarnish,
  BuyKind.glass => pText.readyBuyGlass,
  BuyKind.glazingBlocks => pText.readyBuyGlazingBlocks,
  BuyKind.silicone => pText.readyBuySilicone,
  BuyKind.pins => pText.readyBuyPins,
  BuyKind.frameScrews => pText.readyBuyFrameScrews,
  BuyKind.joistHangers => pText.readyBuyJoistHangers,
  BuyKind.hangerNails => pText.readyBuyHangerNails,
  BuyKind.anchorBolts => pText.readyBuyAnchorBolts,
  BuyKind.floorScrews => pText.readyBuyFloorScrews,
  BuyKind.postBases => pText.readyBuyPostBases,
  BuyKind.plasterScrews => pText.readyBuyPlasterScrews,
  BuyKind.cornerBead => pText.readyBuyCornerBead,
  BuyKind.jointTape => pText.readyBuyJointTape,
  BuyKind.jointCompound => pText.readyBuyJointCompound,
};

String readyStepLabel(AppLocalizations pText, StepKind pKind) => switch (pKind) {
  StepKind.measure => pText.readyStepMeasure,
  StepKind.cutBoards => pText.readyStepCutBoards,
  StepKind.sand => pText.readyStepSand,
  StepKind.drillWall => pText.readyStepDrillWall,
  StepKind.fixCleat => pText.readyStepFixCleat,
  StepKind.setShelf => pText.readyStepSetShelf,
  StepKind.finish => pText.readyStepFinish,
  StepKind.cutFrame => pText.readyStepCutFrame,
  StepKind.rebate => pText.readyStepRebate,
  StepKind.assembleFrame => pText.readyStepAssembleFrame,
  StepKind.cutBeads => pText.readyStepCutBeads,
  StepKind.setGlass => pText.readyStepSetGlass,
  StepKind.sealGlass => pText.readyStepSealGlass,
  StepKind.traceLedger => pText.readyStepTraceLedger,
  StepKind.boltLedger => pText.readyStepBoltLedger,
  StepKind.cutJoists => pText.readyStepCutJoists,
  StepKind.fixHangers => pText.readyStepFixHangers,
  StepKind.setJoists => pText.readyStepSetJoists,
  StepKind.setPosts => pText.readyStepSetPosts,
  StepKind.layFloor => pText.readyStepLayFloor,
  StepKind.fixBattens => pText.readyStepFixBattens,
  StepKind.cutPlaster => pText.readyStepCutPlaster,
  StepKind.screwPlaster => pText.readyStepScrewPlaster,
  StepKind.cornerBeads => pText.readyStepCornerBeads,
  StepKind.fillJoints => pText.readyStepFillJoints,
};
