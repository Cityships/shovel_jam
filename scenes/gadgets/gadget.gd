class_name Gadget extends RigidBody2D

signal auto_trigger

func recharge(_amount_rotations : float):
    print("Gadget.gd/recharge")

func force_recharge(_amount_rotations : float):
    print("Gadget.gd/force_recharge")