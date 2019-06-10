from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('normalize', views.normalize, name='normalize'),
    path('result', views.runsql, name='result'),
]