# In case the platform does NOT support this type of sensors
ccflags-y += -I$(srctree)/drivers/misc/mediatek/sensors-1.0/hwmon/include
ccflags-y += -I$(srctree)/drivers/misc/mediatek/sensors-1.0/include

obj-y   +=  accel.o accel_factory.o

obj-$(CONFIG_MTK_BMI160_I2C)   += bmi160-i2c/
#prize-add BMA4XY-pengzhipeng-20180829-start
#prize-add BMA4XY-pengzhipeng-20180829-end
#prize added by huarui, sensor driver, 20190111-start
#prize added by huarui, sensor driver, 20190111-end