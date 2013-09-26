
s = IKServer();
s = s.addRobot('model');
s = s.addAffordance('table');
s = s.setupCosts();
s = s.loadNominalData();

r = s.robot;

nq = r.getNumDOF();
q_nom = s.q_nom;
q_zero = zeros(size(q_nom, 1), 1);

l_foot = r.findLinkInd('l_foot');
r_foot = r.findLinkInd('r_foot');
l_hand = r.findLinkInd('l_hand');
r_hand = r.findLinkInd('r_hand');
utorso = r.findLinkInd('utorso');
pelvis = r.findLinkInd('pelvis');

tspan = [0,1];
gaze_theta = 0.02;
shrink_factor = 0.5;
closest_distance = 0.05;

pelvis_pts = [0;0;0];
l_hand_pts = [0;0;0];
r_hand_pts = [0;0;0];
l_foot_pts = s.getLeftFootPoints();
r_foot_pts = s.getRightFootPoints();

kinsol = doKinematics(r, q_nom);
l_foot_target_start = r.forwardKin(kinsol, l_foot, l_foot_pts);
r_foot_target_start = r.forwardKin(kinsol, r_foot, r_foot_pts);
l_hand_target_start = r.forwardKin(kinsol, l_hand, l_hand_pts);
r_hand_target_start = r.forwardKin(kinsol, r_hand, r_hand_pts);
pelvis_target_start = r.forwardKin(kinsol, pelvis, pelvis_pts);

l_foot_target = l_foot_target_start;
r_foot_target = r_foot_target_start;
l_hand_target = l_hand_target_start;
r_hand_target = r_hand_target_start;
pelvis_target = pelvis_target_start;

l_foot_position_constraint = WorldPositionConstraint(r, l_foot, l_foot_pts, l_foot_target, l_foot_target, tspan);
r_foot_position_constraint = WorldPositionConstraint(r, r_foot, r_foot_pts, r_foot_target, r_foot_target, tspan);
l_hand_position_constraint = WorldPositionConstraint(r, l_hand, l_hand_pts, l_hand_target, l_hand_target, tspan);
r_hand_position_constraint = WorldPositionConstraint(r, r_hand, r_hand_pts, r_hand_target, r_hand_target, tspan);
pelvis_position_constraint = WorldPositionConstraint(r, pelvis, pelvis_pts, pelvis_target, pelvis_target, tspan);

l_hand_gaze_constraint = WorldGazeDirConstraint(r, l_hand, [0;0;1], [0;0;1], gaze_theta, tspan);
l_hand_gaze_constraint2 = WorldGazeDirConstraint(r, l_hand, [0;1;0], [0;1;0], gaze_theta, tspan);
r_hand_gaze_constraint = WorldGazeDirConstraint(r, r_hand, [0;0;1], [0;0;1], gaze_theta, tspan);
pelvis_gaze_constraint = WorldGazeDirConstraint(r, pelvis, [0;0;1], [0;0;1], gaze_theta, tspan);
utorso_gaze_constraint = WorldGazeDirConstraint(r, utorso, [0;0;1], [0;0;1], gaze_theta, tspan);

self_collision_constraint = AllBodiesClosestDistanceConstraint(r, closest_distance, 1e3, tspan);

both_feet_qsc = QuasiStaticConstraint(r);
both_feet_qsc = both_feet_qsc.setShrinkFactor(shrink_factor);
both_feet_qsc = both_feet_qsc.addContact(r_foot, r_foot_pts);
both_feet_qsc = both_feet_qsc.addContact(l_foot, l_foot_pts);
both_feet_qsc = both_feet_qsc.setActive(true);

l_foot_qsc = QuasiStaticConstraint(r);
l_foot_qsc = both_feet_qsc.setShrinkFactor(shrink_factor);
l_foot_qsc = both_feet_qsc.addContact(l_foot, l_foot_pts);
l_foot_qsc = both_feet_qsc.setActive(true);

r_foot_qsc = QuasiStaticConstraint(r);
r_foot_qsc = both_feet_qsc.setShrinkFactor(shrink_factor);
r_foot_qsc = both_feet_qsc.addContact(r_foot, r_foot_pts);
r_foot_qsc = both_feet_qsc.setActive(true);

posture_constraint = PostureConstraint(r, tspan);
posture_constraint = setJointLimits(posture_constraint, (1:nq)', q_nom, q_nom);


active_constraints = {both_feet_qsc, l_foot_position_constraint, r_foot_position_constraint, utorso_gaze_constraint};

[q_start, info] = inverseKin(r, q_nom, q_nom, active_constraints{:}, s.ikoptions);
q_end = q_start;



qtraj = PPTrajectory(foh(tspan, [q_start, q_end]));
nt = 5;

t = linspace(0, 1, nt);


% args:
% RigidBodyManipulator
% starting joint position
% starting joint velocity
% time points
% join position seeds
% joint nominal positions
% constraints...
% ikoptions

[xtraj, info] = inverseKinTraj(r, q_start, zeros(nq,1), t, squeeze(eval(qtraj,t(2:end))), repmat(q_nom, 1, nt-1), active_constraints{:}, s.ikoptions);
qtraj = xtraj(1:nq);

